DROP TABLE IF EXISTS marts.mart_store_reconciliation_performance;

CREATE TABLE marts.mart_store_reconciliation_performance (
    store_id VARCHAR(10) NOT NULL,

    store_name VARCHAR(100) NOT NULL,

    total_transactions BIGINT NOT NULL,

    matched_transactions BIGINT NOT NULL,

    exception_transactions BIGINT NOT NULL,

    match_rate_pct NUMERIC(10,2) NOT NULL,

    total_pos_amount NUMERIC(18,2) NOT NULL,

    total_settled_amount NUMERIC(18,2) NOT NULL,

    net_amount_difference NUMERIC(18,2) NOT NULL
);