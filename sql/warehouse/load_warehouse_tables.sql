TRUNCATE TABLE warehouse.fact_pos_transactions;

INSERT INTO warehouse.fact_pos_transactions
SELECT
    pos_transaction_id,
    transaction_date::DATE,
    store_id,
    store_name,
    payment_method,
    gross_amount::NUMERIC(10,2),
    currency,
    transaction_status
FROM staging.pos_transactions;


TRUNCATE TABLE warehouse.fact_bank_settlements;

INSERT INTO warehouse.fact_bank_settlements
SELECT
    bank_transaction_id,
    settlement_date::DATE,
    reference_id,
    store_id,
    settled_amount::NUMERIC(10,2),
    currency,
    bank_account
FROM staging.bank_settlements;