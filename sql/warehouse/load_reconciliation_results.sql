TRUNCATE TABLE warehouse.fact_reconciliation_results;

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

pos_with_expected_channel AS (

    SELECT
        pos_transaction_id,
        transaction_date,
        store_id,
        payment_method,
        gross_amount,
        CASE
            WHEN payment_method IN ('Visa', 'Mastercard', 'Amex')
                THEN 'CARD'
            WHEN payment_method = 'Cash'
                THEN 'CASH'
            WHEN payment_method = 'Room Charge'
                THEN 'GUEST_LEDGER'
            WHEN payment_method = 'Corporate Account'
                THEN 'CORPORATE_RECEIVABLE'
            ELSE 'UNKNOWN'
        END AS expected_settlement_channel
    FROM warehouse.fact_pos_transactions

),

duplicate_settlements AS (

    SELECT
        reference_id,
        settlement_channel
    FROM normalized_settlements
    GROUP BY
        reference_id,
        settlement_channel
    HAVING COUNT(*) > 1

)

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
    reconciliation_status

)

SELECT

    p.pos_transaction_id,
    s.settlement_transaction_id,

    p.transaction_date,
    s.settlement_date,

    p.store_id,

    p.payment_method,
    p.expected_settlement_channel AS settlement_channel,

    p.gross_amount AS pos_amount,
    s.settled_amount,

    COALESCE(
        p.gross_amount - s.settled_amount,
        p.gross_amount
    ) AS amount_difference,

    CASE

        WHEN s.reference_id IS NULL
            THEN 'MISSING_SETTLEMENT'

        WHEN d.reference_id IS NOT NULL
            THEN 'DUPLICATE_SETTLEMENT'

        WHEN p.gross_amount <> s.settled_amount
            THEN 'AMOUNT_MISMATCH'

        WHEN (s.settlement_date - p.transaction_date) > 3
            THEN 'DELAYED_SETTLEMENT'

        ELSE 'MATCHED'

    END AS reconciliation_status

FROM pos_with_expected_channel p

LEFT JOIN normalized_settlements s
    ON p.pos_transaction_id = s.reference_id
    AND p.expected_settlement_channel = s.settlement_channel

LEFT JOIN duplicate_settlements d
    ON p.pos_transaction_id = d.reference_id
    AND p.expected_settlement_channel = d.settlement_channel;