TRUNCATE TABLE marts.mart_reconciliation_summary;

INSERT INTO marts.mart_reconciliation_summary (

    reconciliation_status,
    transaction_count,
    percentage_of_total

)

SELECT

    reconciliation_status,

    COUNT(*) AS transaction_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_total

FROM warehouse.fact_reconciliation_results

GROUP BY reconciliation_status;