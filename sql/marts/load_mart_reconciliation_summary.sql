TRUNCATE TABLE marts.mart_reconciliation_summary;

INSERT INTO marts.mart_reconciliation_summary (
    reconciliation_status,
    transaction_count,
    percentage_of_total,
    total_pos_amount,
    total_settled_amount,
    net_amount_difference
)
SELECT
    reconciliation_status,

    COUNT(*) AS transaction_count,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_total,

    ROUND(
        SUM(pos_amount),
        2
    ) AS total_pos_amount,

    ROUND(
        SUM(COALESCE(settled_amount, 0)),
        2
    ) AS total_settled_amount,

    ROUND(
        SUM(amount_difference),
        2
    ) AS net_amount_difference

FROM warehouse.fact_reconciliation_results

GROUP BY reconciliation_status;