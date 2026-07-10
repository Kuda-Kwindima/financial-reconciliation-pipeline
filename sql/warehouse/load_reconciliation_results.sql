TRUNCATE TABLE warehouse.fact_reconciliation_results
RESTART IDENTITY;


-- ============================================================
-- NORMALIZE ALL TRUSTED SETTLEMENT FACTS INTO ONE STRUCTURE
-- ============================================================

WITH normalized_settlements AS (

    SELECT
        bank_transaction_id AS settlement_transaction_id,
        settlement_date,
        reference_id,
        store_id,
        settled_amount,
        'CARD' AS settlement_channel

    FROM warehouse.fact_bank_settlements


    UNION ALL


    SELECT
        cash_transaction_id AS settlement_transaction_id,
        deposit_date AS settlement_date,
        reference_id,
        store_id,
        deposited_amount AS settled_amount,
        'CASH' AS settlement_channel

    FROM warehouse.fact_cash_deposits


    UNION ALL


    SELECT
        ledger_transaction_id AS settlement_transaction_id,
        ledger_settlement_date AS settlement_date,
        reference_id,
        store_id,
        ledger_amount AS settled_amount,
        'GUEST_LEDGER' AS settlement_channel

    FROM warehouse.fact_guest_ledger_settlements


    UNION ALL


    SELECT
        corp_transaction_id AS settlement_transaction_id,
        receivable_settlement_date AS settlement_date,
        reference_id,
        store_id,
        receivable_amount AS settled_amount,
        'CORPORATE_RECEIVABLE' AS settlement_channel

    FROM warehouse.fact_corporate_receivables

),


-- ============================================================
-- ENRICH POS FACTS USING DIMENSIONS
-- ============================================================

pos_enriched AS (

    SELECT
        p.pos_transaction_id,
        p.transaction_date,

        s.store_id,

        pm.payment_method,
        pm.settlement_channel AS expected_settlement_channel,

        p.gross_amount

    FROM warehouse.fact_pos_transactions p

    JOIN warehouse.dim_store s
        ON p.store_key = s.store_key

    JOIN warehouse.dim_payment_method pm
        ON p.payment_method_key = pm.payment_method_key

),


-- ============================================================
-- AGGREGATE SETTLEMENTS TO ONE ROW PER REFERENCE AND CHANNEL
-- ============================================================

settlement_summary AS (

    SELECT
        reference_id,
        settlement_channel,

        MIN(settlement_transaction_id)
            AS representative_settlement_transaction_id,

        MIN(settlement_date)
            AS first_settlement_date,

        SUM(settled_amount)
            AS total_settled_amount,

        COUNT(*)
            AS settlement_record_count

    FROM normalized_settlements

    GROUP BY
        reference_id,
        settlement_channel

)


-- ============================================================
-- CREATE ONE RECONCILIATION ROW PER ACCEPTED POS TRANSACTION
-- ============================================================

INSERT INTO warehouse.fact_reconciliation_results (
    pos_transaction_id,
    settlement_transaction_id,
    transaction_date,
    settlement_date,
    store_id,
    payment_method,
    settlement_channel,
    pos_amount,
    settled_amount,
    amount_difference,
    settlement_record_count,
    reconciliation_status
)

SELECT
    p.pos_transaction_id,

    s.representative_settlement_transaction_id,

    p.transaction_date,

    s.first_settlement_date,

    p.store_id,

    p.payment_method,

    p.expected_settlement_channel,

    p.gross_amount AS pos_amount,

    s.total_settled_amount AS settled_amount,

    p.gross_amount
        - COALESCE(s.total_settled_amount, 0)
        AS amount_difference,

    COALESCE(s.settlement_record_count, 0)
        AS settlement_record_count,

    CASE
        WHEN s.reference_id IS NULL
            THEN 'MISSING_SETTLEMENT'

        WHEN s.settlement_record_count > 1
            THEN 'DUPLICATE_SETTLEMENT'

        WHEN p.gross_amount <> s.total_settled_amount
            THEN 'AMOUNT_MISMATCH'

        WHEN (
            s.first_settlement_date
            - p.transaction_date
        ) > 3
            THEN 'DELAYED_SETTLEMENT'

        ELSE 'MATCHED'
    END AS reconciliation_status

FROM pos_enriched p

LEFT JOIN settlement_summary s
    ON p.pos_transaction_id = s.reference_id
    AND p.expected_settlement_channel = s.settlement_channel;