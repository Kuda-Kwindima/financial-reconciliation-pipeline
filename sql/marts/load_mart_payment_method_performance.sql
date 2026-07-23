TRUNCATE TABLE marts.mart_payment_method_performance;

INSERT INTO marts.mart_payment_method_performance (
    payment_method,
    settlement_channel,
    total_transactions,
    matched_transactions,
    exception_transactions,
    match_rate_pct,
    total_pos_amount,
    total_settled_amount,
    net_amount_difference
)
SELECT
    payment_method,

    settlement_channel,

    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE reconciliation_status = 'MATCHED'
    ) AS matched_transactions,

    COUNT(*) FILTER (
        WHERE reconciliation_status <> 'MATCHED'
    ) AS exception_transactions,

    ROUND(
        COUNT(*) FILTER (
            WHERE reconciliation_status = 'MATCHED'
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS match_rate_pct,

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

GROUP BY
    payment_method,
    settlement_channel;