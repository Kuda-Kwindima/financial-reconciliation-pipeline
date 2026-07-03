TRUNCATE TABLE warehouse.fact_reconciliation_results;

WITH duplicate_settlements AS (

    SELECT
        reference_id
    FROM warehouse.fact_bank_settlements
    GROUP BY reference_id
    HAVING COUNT(*) > 1

)

INSERT INTO warehouse.fact_reconciliation_results (

    pos_transaction_id,
    bank_transaction_id,
    transaction_date,
    settlement_date,
    store_id,
    pos_amount,
    settled_amount,
    amount_difference,
    reconciliation_status

)

SELECT

    p.pos_transaction_id,

    b.bank_transaction_id,

    p.transaction_date,

    b.settlement_date,

    p.store_id,

    p.gross_amount AS pos_amount,

    b.settled_amount,

    COALESCE(
        p.gross_amount - b.settled_amount,
        p.gross_amount
    )