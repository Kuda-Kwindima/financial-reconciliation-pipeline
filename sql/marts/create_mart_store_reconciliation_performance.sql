CREATE TABLE IF NOT EXISTS marts.mart_store_reconciliation_performance (

    store_id VARCHAR(10),

    store_name VARCHAR(100),

    total_transactions BIGINT,

    matched_transactions BIGINT,

    exception_transactions BIGINT,

    match_rate_pct NUMERIC(10,2)

);