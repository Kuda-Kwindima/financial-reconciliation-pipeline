CREATE TABLE IF NOT EXISTS marts.mart_payment_method_performance (

    payment_method VARCHAR(50),

    settlement_channel VARCHAR(50),

    total_transactions BIGINT,

    matched_transactions BIGINT,

    exception_transactions BIGINT,

    match_rate_pct NUMERIC(10,2)

);