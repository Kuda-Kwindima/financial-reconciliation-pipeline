CREATE TABLE IF NOT EXISTS marts.mart_reconciliation_summary (

    reconciliation_status VARCHAR(50),

    transaction_count BIGINT,

    percentage_of_total NUMERIC(10,2)

);