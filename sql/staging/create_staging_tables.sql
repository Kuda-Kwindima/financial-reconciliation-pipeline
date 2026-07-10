CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.pos_transactions (
    staging_record_id BIGSERIAL PRIMARY KEY,
    pos_transaction_id TEXT,
    transaction_date TEXT,
    store_id TEXT,
    store_name TEXT,
    payment_method TEXT,
    gross_amount TEXT,
    currency TEXT,
    transaction_status TEXT,
    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.bank_settlements (
    staging_record_id BIGSERIAL PRIMARY KEY,
    bank_transaction_id TEXT,
    settlement_date TEXT,
    reference_id TEXT,
    store_id TEXT,
    settled_amount TEXT,
    currency TEXT,
    bank_account TEXT,
    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.cash_deposits (
    staging_record_id BIGSERIAL PRIMARY KEY,
    cash_transaction_id TEXT,
    deposit_date TEXT,
    reference_id TEXT,
    store_id TEXT,
    deposited_amount TEXT,
    currency TEXT,
    cash_account TEXT,
    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.guest_ledger_settlements (
    staging_record_id BIGSERIAL PRIMARY KEY,
    ledger_transaction_id TEXT,
    ledger_settlement_date TEXT,
    reference_id TEXT,
    store_id TEXT,
    ledger_amount TEXT,
    currency TEXT,
    ledger_account TEXT,
    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.corporate_receivables (
    staging_record_id BIGSERIAL PRIMARY KEY,
    corp_transaction_id TEXT,
    receivable_settlement_date TEXT,
    reference_id TEXT,
    store_id TEXT,
    receivable_amount TEXT,
    currency TEXT,
    receivable_account TEXT,
    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
