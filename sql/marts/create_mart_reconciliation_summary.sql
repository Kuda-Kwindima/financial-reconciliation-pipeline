DROP TABLE IF EXISTS marts.mart_reconciliation_summary;

CREATE TABLE marts.mart_reconciliation_summary (
    reconciliation_status VARCHAR(50) NOT NULL,

    transaction_count BIGINT NOT NULL,

    percentage_of_total NUMERIC(10,2) NOT NULL,

    total_pos_amount NUMERIC(18,2) NOT NULL,

    total_settled_amount NUMERIC(18,2) NOT NULL,

    net_amount_difference NUMERIC(18,2) NOT NULL
);