DROP TABLE IF EXISTS marts.mart_exception_summary;

CREATE TABLE marts.mart_exception_summary (
    pos_transaction_id VARCHAR(50) NOT NULL,

    settlement_transaction_id VARCHAR(50),

    transaction_date DATE NOT NULL,

    settlement_date DATE,

    store_id VARCHAR(10) NOT NULL,

    payment_method VARCHAR(50) NOT NULL,

    settlement_channel VARCHAR(50) NOT NULL,

    pos_amount NUMERIC(12,2) NOT NULL,

    settled_amount NUMERIC(12,2),

    amount_difference NUMERIC(12,2) NOT NULL,

    settlement_record_count INTEGER NOT NULL,

    reconciliation_status VARCHAR(50) NOT NULL,

    reconciliation_timestamp TIMESTAMPTZ NOT NULL
);