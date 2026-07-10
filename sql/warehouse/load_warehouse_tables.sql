TRUNCATE TABLE
    warehouse.fact_pos_transactions,
    warehouse.fact_bank_settlements,
    warehouse.fact_cash_deposits,
    warehouse.fact_guest_ledger_settlements,
    warehouse.fact_corporate_receivables,
    warehouse.rejected_pos_transactions,
    warehouse.excluded_pos_transactions,
    warehouse.rejected_settlements,
    warehouse.dim_store,
    warehouse.dim_payment_method
RESTART IDENTITY CASCADE;


-- ============================================================
-- DIMENSIONS
-- ============================================================

INSERT INTO warehouse.dim_store (
    store_id,
    store_name
)
VALUES
    ('DR001', 'Main Restaurant'),
    ('DR002', 'Pool Bar'),
    ('DR003', 'Lobby Lounge');


INSERT INTO warehouse.dim_payment_method (
    payment_method,
    settlement_channel
)
VALUES
    ('Visa', 'CARD'),
    ('Mastercard', 'CARD'),
    ('Amex', 'CARD'),
    ('Cash', 'CASH'),
    ('Room Charge', 'GUEST_LEDGER'),
    ('Corporate Account', 'CORPORATE_RECEIVABLE');


-- ============================================================
-- POS NORMALIZATION
-- ============================================================

DROP TABLE IF EXISTS tmp_pos_normalized;

CREATE TEMP TABLE tmp_pos_normalized AS
WITH normalized AS (
    SELECT
        staging_record_id,

        pos_transaction_id AS raw_pos_transaction_id,
        transaction_date AS raw_transaction_date,
        store_id AS raw_store_id,
        store_name AS raw_store_name,
        payment_method AS raw_payment_method,
        gross_amount AS raw_gross_amount,
        currency AS raw_currency,
        transaction_status AS raw_transaction_status,

        NULLIF(
            UPPER(TRIM(pos_transaction_id)),
            ''
        ) AS cleaned_pos_transaction_id,

        CASE
            WHEN TRIM(transaction_date)
                ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN TRIM(transaction_date)::DATE
            ELSE NULL
        END AS cleaned_transaction_date,

        UPPER(TRIM(store_id)) AS cleaned_store_id,

        CASE UPPER(TRIM(payment_method))
            WHEN 'VISA' THEN 'Visa'
            WHEN 'VISA CARD' THEN 'Visa'
            WHEN 'MASTERCARD' THEN 'Mastercard'
            WHEN 'AMEX' THEN 'Amex'
            WHEN 'CASH' THEN 'Cash'
            WHEN 'ROOM CHARGE' THEN 'Room Charge'
            WHEN 'CORPORATE ACCOUNT' THEN 'Corporate Account'
            ELSE NULL
        END AS cleaned_payment_method,

        regexp_replace(
            TRIM(gross_amount),
            '[$, ]',
            '',
            'g'
        ) AS cleaned_amount_text,

        UPPER(TRIM(currency)) AS cleaned_currency,

        CASE UPPER(TRIM(transaction_status))
            WHEN 'COMPLETED' THEN 'Completed'
            WHEN 'COMPLETE' THEN 'Completed'
            WHEN 'CANCELLED' THEN 'Cancelled'
            WHEN 'CANCELED' THEN 'Cancelled'
            ELSE NULL
        END AS cleaned_transaction_status,

        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at

    FROM staging.pos_transactions
),
typed AS (
    SELECT
        *,

        CASE
            WHEN cleaned_amount_text
                ~ '^[0-9]+(\.[0-9]{1,2})?$'
            THEN cleaned_amount_text::NUMERIC(12,2)
            ELSE NULL
        END AS cleaned_gross_amount

    FROM normalized
)
SELECT
    *,

    CONCAT_WS(
        '; ',

        CASE
            WHEN cleaned_pos_transaction_id IS NULL
            THEN 'MISSING_POS_TRANSACTION_ID'
        END,

        CASE
            WHEN cleaned_transaction_date IS NULL
            THEN 'INVALID_TRANSACTION_DATE'
        END,

        CASE
            WHEN cleaned_store_id NOT IN (
                'DR001',
                'DR002',
                'DR003'
            )
            THEN 'INVALID_STORE_ID'
        END,

        CASE
            WHEN cleaned_payment_method IS NULL
            THEN 'INVALID_PAYMENT_METHOD'
        END,

        CASE
            WHEN cleaned_gross_amount IS NULL
            THEN 'INVALID_GROSS_AMOUNT'
        END,

        CASE
            WHEN cleaned_gross_amount <= 0
            THEN 'NON_POSITIVE_GROSS_AMOUNT'
        END,

        CASE
            WHEN cleaned_currency <> 'USD'
                OR cleaned_currency = ''
            THEN 'INVALID_CURRENCY'
        END,

        CASE
            WHEN cleaned_transaction_status IS NULL
            THEN 'INVALID_TRANSACTION_STATUS'
        END

    ) AS rejection_reason

FROM typed;


-- ============================================================
-- REJECTED POS TRANSACTIONS
-- ============================================================

INSERT INTO warehouse.rejected_pos_transactions (
    staging_record_id,
    pos_transaction_id,
    transaction_date,
    store_id,
    store_name,
    payment_method,
    gross_amount,
    currency,
    transaction_status,
    rejection_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    staging_record_id,
    raw_pos_transaction_id,
    raw_transaction_date,
    raw_store_id,
    raw_store_name,
    raw_payment_method,
    raw_gross_amount,
    raw_currency,
    raw_transaction_status,
    rejection_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_pos_normalized

WHERE rejection_reason <> '';


-- ============================================================
-- EXCLUDED CANCELLED TRANSACTIONS
-- ============================================================

INSERT INTO warehouse.excluded_pos_transactions (
    staging_record_id,
    pos_transaction_id,
    transaction_date,
    store_id,
    store_name,
    payment_method,
    gross_amount,
    currency,
    transaction_status,
    exclusion_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    staging_record_id,
    raw_pos_transaction_id,
    raw_transaction_date,
    raw_store_id,
    raw_store_name,
    raw_payment_method,
    raw_gross_amount,
    raw_currency,
    raw_transaction_status,
    'CANCELLED_TRANSACTION',
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_pos_normalized

WHERE rejection_reason = ''
  AND cleaned_transaction_status = 'Cancelled';


-- ============================================================
-- VALID COMPLETED POS TRANSACTIONS WITH DUPLICATE RANK
-- ============================================================

DROP TABLE IF EXISTS tmp_valid_completed_pos;

CREATE TEMP TABLE tmp_valid_completed_pos AS
SELECT
    *,

    ROW_NUMBER() OVER (
        PARTITION BY cleaned_pos_transaction_id
        ORDER BY staging_record_id
    ) AS duplicate_rank

FROM tmp_pos_normalized

WHERE rejection_reason = ''
  AND cleaned_transaction_status = 'Completed';


-- ============================================================
-- EXCLUDED DUPLICATE POS TRANSACTIONS
-- ============================================================

INSERT INTO warehouse.excluded_pos_transactions (
    staging_record_id,
    pos_transaction_id,
    transaction_date,
    store_id,
    store_name,
    payment_method,
    gross_amount,
    currency,
    transaction_status,
    exclusion_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    staging_record_id,
    raw_pos_transaction_id,
    raw_transaction_date,
    raw_store_id,
    raw_store_name,
    raw_payment_method,
    raw_gross_amount,
    raw_currency,
    raw_transaction_status,
    'DUPLICATE_SOURCE_RECORD',
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_valid_completed_pos

WHERE duplicate_rank > 1;


-- ============================================================
-- ACCEPTED POS FACT
-- ============================================================

INSERT INTO warehouse.fact_pos_transactions (
    pos_transaction_id,
    transaction_date,
    store_key,
    payment_method_key,
    gross_amount,
    currency,
    transaction_status,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    p.cleaned_pos_transaction_id,
    p.cleaned_transaction_date,
    s.store_key,
    pm.payment_method_key,
    p.cleaned_gross_amount,
    p.cleaned_currency,
    p.cleaned_transaction_status,
    p.source_file,
    p.source_row_number,
    p.pipeline_run_id,
    p.ingested_at

FROM tmp_valid_completed_pos p

JOIN warehouse.dim_store s
    ON p.cleaned_store_id = s.store_id

JOIN warehouse.dim_payment_method pm
    ON p.cleaned_payment_method = pm.payment_method

WHERE p.duplicate_rank = 1;


-- ============================================================
-- SETTLEMENT NORMALIZATION
-- ============================================================

DROP TABLE IF EXISTS tmp_settlement_normalized;

CREATE TEMP TABLE tmp_settlement_normalized AS
WITH combined_settlements AS (

    SELECT
        'BANK' AS settlement_source,
        staging_record_id,
        bank_transaction_id AS settlement_transaction_id,
        settlement_date,
        reference_id,
        store_id,
        settled_amount AS settlement_amount,
        currency,
        bank_account AS settlement_account,
        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at
    FROM staging.bank_settlements

    UNION ALL

    SELECT
        'CASH' AS settlement_source,
        staging_record_id,
        cash_transaction_id AS settlement_transaction_id,
        deposit_date AS settlement_date,
        reference_id,
        store_id,
        deposited_amount AS settlement_amount,
        currency,
        cash_account AS settlement_account,
        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at
    FROM staging.cash_deposits

    UNION ALL

    SELECT
        'GUEST_LEDGER' AS settlement_source,
        staging_record_id,
        ledger_transaction_id AS settlement_transaction_id,
        ledger_settlement_date AS settlement_date,
        reference_id,
        store_id,
        ledger_amount AS settlement_amount,
        currency,
        ledger_account AS settlement_account,
        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at
    FROM staging.guest_ledger_settlements

    UNION ALL

    SELECT
        'CORPORATE_RECEIVABLE' AS settlement_source,
        staging_record_id,
        corp_transaction_id AS settlement_transaction_id,
        receivable_settlement_date AS settlement_date,
        reference_id,
        store_id,
        receivable_amount AS settlement_amount,
        currency,
        receivable_account AS settlement_account,
        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at
    FROM staging.corporate_receivables
),
normalized AS (
    SELECT
        settlement_source,
        staging_record_id,

        settlement_transaction_id
            AS raw_settlement_transaction_id,

        settlement_date
            AS raw_settlement_date,

        reference_id
            AS raw_reference_id,

        store_id
            AS raw_store_id,

        settlement_amount
            AS raw_settlement_amount,

        currency
            AS raw_currency,

        settlement_account
            AS raw_settlement_account,

        NULLIF(
            UPPER(TRIM(settlement_transaction_id)),
            ''
        ) AS cleaned_settlement_transaction_id,

        CASE
            WHEN TRIM(settlement_date)
                ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN TRIM(settlement_date)::DATE
            ELSE NULL
        END AS cleaned_settlement_date,

        NULLIF(
            UPPER(TRIM(reference_id)),
            ''
        ) AS cleaned_reference_id,

        NULLIF(
            UPPER(TRIM(store_id)),
            ''
        ) AS cleaned_store_id,

        regexp_replace(
            TRIM(settlement_amount),
            '[$, ]',
            '',
            'g'
        ) AS cleaned_amount_text,

        NULLIF(
            UPPER(TRIM(currency)),
            ''
        ) AS cleaned_currency,

        NULLIF(
            TRIM(settlement_account),
            ''
        ) AS cleaned_settlement_account,

        source_file,
        source_row_number,
        pipeline_run_id,
        ingested_at

    FROM combined_settlements
),
typed AS (
    SELECT
        *,

        CASE
            WHEN cleaned_amount_text
                ~ '^[0-9]+(\.[0-9]{1,2})?$'
            THEN cleaned_amount_text::NUMERIC(12,2)
            ELSE NULL
        END AS cleaned_settlement_amount

    FROM normalized
)
SELECT
    *,

    CONCAT_WS(
        '; ',

        CASE
            WHEN cleaned_settlement_transaction_id IS NULL
            THEN 'MISSING_SETTLEMENT_TRANSACTION_ID'
        END,

        CASE
            WHEN cleaned_settlement_date IS NULL
            THEN 'INVALID_SETTLEMENT_DATE'
        END,

        CASE
            WHEN cleaned_reference_id IS NULL
            THEN 'MISSING_REFERENCE_ID'
        END,

        CASE
            WHEN cleaned_store_id IS NULL
            THEN 'MISSING_STORE_ID'
        END,

        CASE
            WHEN cleaned_settlement_amount IS NULL
            THEN 'INVALID_SETTLEMENT_AMOUNT'
        END,

        CASE
            WHEN cleaned_settlement_amount <= 0
            THEN 'NON_POSITIVE_SETTLEMENT_AMOUNT'
        END,

        CASE
            WHEN cleaned_currency IS NULL
            THEN 'MISSING_CURRENCY'
        END,

        CASE
            WHEN LENGTH(cleaned_currency) <> 3
            THEN 'INVALID_CURRENCY_CODE'
        END,

        CASE
            WHEN cleaned_settlement_account IS NULL
            THEN 'MISSING_SETTLEMENT_ACCOUNT'
        END

    ) AS rejection_reason

FROM typed;


-- ============================================================
-- REJECTED SETTLEMENTS
-- ============================================================

INSERT INTO warehouse.rejected_settlements (
    settlement_source,
    staging_record_id,
    settlement_transaction_id,
    settlement_date,
    reference_id,
    store_id,
    settlement_amount,
    currency,
    settlement_account,
    rejection_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    settlement_source,
    staging_record_id,
    raw_settlement_transaction_id,
    raw_settlement_date,
    raw_reference_id,
    raw_store_id,
    raw_settlement_amount,
    raw_currency,
    raw_settlement_account,
    rejection_reason,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_settlement_normalized

WHERE rejection_reason <> '';


-- ============================================================
-- ACCEPTED BANK SETTLEMENTS
-- ============================================================

INSERT INTO warehouse.fact_bank_settlements (
    bank_transaction_id,
    settlement_date,
    reference_id,
    store_id,
    settled_amount,
    currency,
    bank_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    cleaned_settlement_transaction_id,
    cleaned_settlement_date,
    cleaned_reference_id,
    cleaned_store_id,
    cleaned_settlement_amount,
    cleaned_currency,
    cleaned_settlement_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_settlement_normalized

WHERE settlement_source = 'BANK'
  AND rejection_reason = '';


-- ============================================================
-- ACCEPTED CASH DEPOSITS
-- ============================================================

INSERT INTO warehouse.fact_cash_deposits (
    cash_transaction_id,
    deposit_date,
    reference_id,
    store_id,
    deposited_amount,
    currency,
    cash_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    cleaned_settlement_transaction_id,
    cleaned_settlement_date,
    cleaned_reference_id,
    cleaned_store_id,
    cleaned_settlement_amount,
    cleaned_currency,
    cleaned_settlement_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_settlement_normalized

WHERE settlement_source = 'CASH'
  AND rejection_reason = '';


-- ============================================================
-- ACCEPTED GUEST LEDGER SETTLEMENTS
-- ============================================================

INSERT INTO warehouse.fact_guest_ledger_settlements (
    ledger_transaction_id,
    ledger_settlement_date,
    reference_id,
    store_id,
    ledger_amount,
    currency,
    ledger_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    cleaned_settlement_transaction_id,
    cleaned_settlement_date,
    cleaned_reference_id,
    cleaned_store_id,
    cleaned_settlement_amount,
    cleaned_currency,
    cleaned_settlement_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_settlement_normalized

WHERE settlement_source = 'GUEST_LEDGER'
  AND rejection_reason = '';


-- ============================================================
-- ACCEPTED CORPORATE RECEIVABLES
-- ============================================================

INSERT INTO warehouse.fact_corporate_receivables (
    corp_transaction_id,
    receivable_settlement_date,
    reference_id,
    store_id,
    receivable_amount,
    currency,
    receivable_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at
)
SELECT
    cleaned_settlement_transaction_id,
    cleaned_settlement_date,
    cleaned_reference_id,
    cleaned_store_id,
    cleaned_settlement_amount,
    cleaned_currency,
    cleaned_settlement_account,
    source_file,
    source_row_number,
    pipeline_run_id,
    ingested_at

FROM tmp_settlement_normalized

WHERE settlement_source = 'CORPORATE_RECEIVABLE'
  AND rejection_reason = '';