TRUNCATE TABLE marts.mart_store_reconciliation_performance;

INSERT INTO marts.mart_store_reconciliation_performance (
    store_id,
    store_name,
    total_transactions,
    matched_transactions,
    exception_transactions,
    match_rate_pct,
    total_pos_amount,
    total_settled_amount,
    net_amount_difference
)
SELECT
    r.store_id,

    s.store_name,

    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE r.reconciliation_status = 'MATCHED'
    ) AS matched_transactions,

    COUNT(*) FILTER (
        WHERE r.reconciliation_status <> 'MATCHED'
    ) AS exception_transactions,

    ROUND(
        COUNT(*) FILTER (
            WHERE r.reconciliation_status = 'MATCHED'
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS match_rate_pct,

    ROUND(
        SUM(r.pos_amount),
        2
    ) AS total_pos_amount,

    ROUND(
        SUM(COALESCE(r.settled_amount, 0)),
        2
    ) AS total_settled_amount,

    ROUND(
        SUM(r.amount_difference),
        2
    ) AS net_amount_difference

FROM warehouse.fact_reconciliation_results r

JOIN warehouse.dim_store s
    ON r.store_id = s.store_id

GROUP BY
    r.store_id,
    s.store_name;