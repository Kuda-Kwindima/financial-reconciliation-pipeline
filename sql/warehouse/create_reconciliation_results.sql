DROP TABLE IF EXISTS warehouse.fact_reconciliation_results;

CREATE TABLE warehouse.fact_reconciliation_results (
    reconciliation_id BIGSERIAL PRIMARY KEY,

    pos_transaction_id VARCHAR(50) NOT NULL UNIQUE,

    settlement_transaction_id VARCHAR(50),

    transaction_date DATE NOT NULL,

    settlement_date DATE,

    store_id VARCHAR(10) NOT NULL,

    payment_method VARCHAR(50) NOT NULL,

    settlement_channel VARCHAR(50) NOT NULL,

    pos_amount NUMERIC(12,2) NOT NULL,

    settled_amount NUMERIC(12,2),

    amount_difference NUMERIC(12,2) NOT NULL,

    settlement_record_count INTEGER NOT NULL DEFAULT 0,

    reconciliation_status VARCHAR(50) NOT NULL
        CHECK (
            reconciliation_status IN (
                'MATCHED',
                'MISSING_SETTLEMENT',
                'DUPLICATE_SETTLEMENT',
                'AMOUNT_MISMATCH',
                'DELAYED_SETTLEMENT'
            )
        ),

    reconciliation_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);