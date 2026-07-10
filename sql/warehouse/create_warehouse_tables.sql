DROP TABLE IF EXISTS warehouse.fact_reconciliation_results CASCADE;

DROP TABLE IF EXISTS warehouse.fact_bank_settlements CASCADE;
DROP TABLE IF EXISTS warehouse.fact_cash_deposits CASCADE;
DROP TABLE IF EXISTS warehouse.fact_guest_ledger_settlements CASCADE;
DROP TABLE IF EXISTS warehouse.fact_corporate_receivables CASCADE;
DROP TABLE IF EXISTS warehouse.fact_pos_transactions CASCADE;

DROP TABLE IF EXISTS warehouse.rejected_pos_transactions CASCADE;
DROP TABLE IF EXISTS warehouse.rejected_settlements CASCADE;
DROP TABLE IF EXISTS warehouse.excluded_pos_transactions CASCADE;

DROP TABLE IF EXISTS warehouse.dim_payment_method CASCADE;
DROP TABLE IF EXISTS warehouse.dim_store CASCADE;


CREATE TABLE warehouse.dim_store (
    store_key SMALLSERIAL PRIMARY KEY,
    store_id VARCHAR(10) NOT NULL UNIQUE,
    store_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE warehouse.dim_payment_method (
    payment_method_key SMALLSERIAL PRIMARY KEY,
    payment_method VARCHAR(50) NOT NULL UNIQUE,
    settlement_channel VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE warehouse.fact_pos_transactions (
    pos_transaction_id VARCHAR(50) PRIMARY KEY,

    transaction_date DATE NOT NULL,

    store_key SMALLINT NOT NULL
        REFERENCES warehouse.dim_store(store_key),

    payment_method_key SMALLINT NOT NULL
        REFERENCES warehouse.dim_payment_method(payment_method_key),

    gross_amount NUMERIC(12,2) NOT NULL
        CHECK (gross_amount > 0),

    currency CHAR(3) NOT NULL
        CHECK (currency = 'USD'),

    transaction_status VARCHAR(20) NOT NULL
        CHECK (transaction_status = 'Completed'),

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.fact_bank_settlements (
    bank_transaction_id VARCHAR(50) PRIMARY KEY,
    settlement_date DATE NOT NULL,
    reference_id VARCHAR(50) NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    settled_amount NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    bank_account VARCHAR(100) NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.fact_cash_deposits (
    cash_transaction_id VARCHAR(50) PRIMARY KEY,
    deposit_date DATE NOT NULL,
    reference_id VARCHAR(50) NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    deposited_amount NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    cash_account VARCHAR(100) NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.fact_guest_ledger_settlements (
    ledger_transaction_id VARCHAR(50) PRIMARY KEY,
    ledger_settlement_date DATE NOT NULL,
    reference_id VARCHAR(50) NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    ledger_amount NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    ledger_account VARCHAR(100) NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.fact_corporate_receivables (
    corp_transaction_id VARCHAR(50) PRIMARY KEY,
    receivable_settlement_date DATE NOT NULL,
    reference_id VARCHAR(50) NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    receivable_amount NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    receivable_account VARCHAR(100) NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.rejected_pos_transactions (
    rejection_id BIGSERIAL PRIMARY KEY,

    staging_record_id BIGINT NOT NULL,
    pos_transaction_id TEXT,
    transaction_date TEXT,
    store_id TEXT,
    store_name TEXT,
    payment_method TEXT,
    gross_amount TEXT,
    currency TEXT,
    transaction_status TEXT,

    rejection_reason TEXT NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    rejected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.excluded_pos_transactions (
    exclusion_id BIGSERIAL PRIMARY KEY,

    staging_record_id BIGINT NOT NULL,
    pos_transaction_id TEXT,
    transaction_date TEXT,
    store_id TEXT,
    store_name TEXT,
    payment_method TEXT,
    gross_amount TEXT,
    currency TEXT,
    transaction_status TEXT,

    exclusion_reason TEXT NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    excluded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE warehouse.rejected_settlements (
    rejection_id BIGSERIAL PRIMARY KEY,

    settlement_source VARCHAR(50) NOT NULL,
    staging_record_id BIGINT NOT NULL,
    settlement_transaction_id TEXT,
    settlement_date TEXT,
    reference_id TEXT,
    store_id TEXT,
    settlement_amount TEXT,
    currency TEXT,
    settlement_account TEXT,

    rejection_reason TEXT NOT NULL,

    source_file TEXT NOT NULL,
    source_row_number BIGINT NOT NULL,
    pipeline_run_id VARCHAR(36) NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    rejected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
