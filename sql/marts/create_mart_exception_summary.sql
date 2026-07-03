DROP TABLE IF EXISTS marts.mart_exception_summary;

CREATE TABLE marts.mart_exception_summary (

    pos_transaction_id VARCHAR(50),

    settlement_transaction_id VARCHAR(50),

    transaction_date DATE,

    settlement_date DATE,

    store_id VARCHAR(10),

    payment_method VARCHAR(50),

    settlement_channel VARCHAR(50),

    pos_amount NUMERIC(10,2),

    settled_amount NUMERIC(10,2),

    amount_difference NUMERIC(10,2),

    reconciliation_status VARCHAR(50)

);