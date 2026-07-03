CREATE TABLE IF NOT EXISTS marts.mart_exception_summary (

    pos_transaction_id VARCHAR(50),

    bank_transaction_id VARCHAR(50),

    transaction_date DATE,

    settlement_date DATE,

    store_id VARCHAR(10),

    pos_amount NUMERIC(10,2),

    settled_amount NUMERIC(10,2),

    amount_difference NUMERIC(10,2),

    reconciliation_status VARCHAR(50)

);