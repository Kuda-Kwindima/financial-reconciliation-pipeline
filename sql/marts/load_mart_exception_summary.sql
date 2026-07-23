TRUNCATE TABLE marts.mart_exception_summary;

INSERT INTO marts.mart_exception_summary (
    pos_transaction_id,
    settlement_transaction_id,
    transaction_date,
    settlement_date,
    store_id,
    payment_method,
    settlement_channel,
    pos_amount,
    settled_amount,
    amount_difference,
    settlement_record_count,
    reconciliation_status,
    reconciliation_timestamp
)
SELECT
    pos_transaction_id,
    settlement_transaction_id,
    transaction_date,
    settlement_date,
    store_id,
    payment_method,
    settlement_channel,
    pos_amount,
    settled_amount,
    amount_difference,
    settlement_record_count,
    reconciliation_status,
    reconciliation_timestamp

FROM warehouse.fact_reconciliation_results

WHERE reconciliation_status <> 'MATCHED';