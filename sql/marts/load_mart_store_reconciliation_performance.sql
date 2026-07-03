TRUNCATE TABLE marts.mart_store_reconciliation_performance;

INSERT INTO marts.mart_store_reconciliation_performance (

    store_id,
    store_name,
    total_transactions,
    matched_transactions,
    exception_transactions,
    match_rate_pct

)

SELECT

    r.store_id,

    MAX(p.store_name) AS store_name,

    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN r.reconciliation_status = 'MATCHED'
            THEN 1
            ELSE 0
        END
    ) AS matched_transactions,

    SUM(
        CASE
            WHEN r.reconciliation_status <> 'MATCHED'
            THEN 1
            ELSE 0
        END
    ) AS exception_transactions,

    ROUND(
        SUM(
            CASE
                WHEN r.reconciliation_status = 'MATCHED'
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*),
        2
    ) AS match_rate_pct

FROM warehouse.fact_reconciliation_results r

LEFT JOIN warehouse.fact_pos_transactions p
    ON r.pos_transaction_id = p.pos_transaction_id

GROUP BY r.store_id;