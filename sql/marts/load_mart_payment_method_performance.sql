TRUNCATE TABLE marts.mart_payment_method_performance;

INSERT INTO marts.mart_payment_method_performance (

    payment_method,
    settlement_channel,
    total_transactions,
    matched_transactions,
    exception_transactions,
    match_rate_pct

)

SELECT

    payment_method,

    settlement_channel,

    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN reconciliation_status = 'MATCHED'
            THEN 1
            ELSE 0
        END
    ) AS matched_transactions,

    SUM(
        CASE
            WHEN reconciliation_status <> 'MATCHED'
            THEN 1
            ELSE 0
        END
    ) AS exception_transactions,

    ROUND(
        SUM(
            CASE
                WHEN reconciliation_status = 'MATCHED'
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*),
        2
    ) AS match_rate_pct

FROM warehouse.fact_reconciliation_results

GROUP BY
    payment_method,
    settlement_channel;