TRUNCATE TABLE warehouse.fact_pos_transactions;

INSERT INTO warehouse.fact_pos_transactions (

    pos_transaction_id,
    transaction_date,
    store_id,
    store_name,
    payment_method,
    gross_amount,
    currency,
    transaction_status

)

SELECT

    pos_transaction_id,
    transaction_date::DATE,
    store_id,
    store_name,
    payment_method,
    gross_amount::NUMERIC(10,2),
    currency,
    transaction_status

FROM staging.pos_transactions;


TRUNCATE TABLE warehouse.fact_bank_settlements;

INSERT INTO warehouse.fact_bank_settlements (

    bank_transaction_id,
    settlement_date,
    reference_id,
    store_id,
    settled_amount,
    currency,
    bank_account

)

SELECT

    bank_transaction_id,
    settlement_date::DATE,
    reference_id,
    store_id,
    settled_amount::NUMERIC(10,2),
    currency,
    bank_account

FROM staging.bank_settlements;


TRUNCATE TABLE warehouse.fact_cash_deposits;

INSERT INTO warehouse.fact_cash_deposits (

    cash_transaction_id,
    deposit_date,
    reference_id,
    store_id,
    deposited_amount,
    currency,
    cash_account

)

SELECT

    cash_transaction_id,
    deposit_date::DATE,
    reference_id,
    store_id,
    deposited_amount::NUMERIC(10,2),
    currency,
    cash_account

FROM staging.cash_deposits;


TRUNCATE TABLE warehouse.fact_guest_ledger_settlements;

INSERT INTO warehouse.fact_guest_ledger_settlements (

    ledger_transaction_id,
    ledger_settlement_date,
    reference_id,
    store_id,
    ledger_amount,
    currency,
    ledger_account

)

SELECT

    ledger_transaction_id,
    ledger_settlement_date::DATE,
    reference_id,
    store_id,
    ledger_amount::NUMERIC(10,2),
    currency,
    ledger_account

FROM staging.guest_ledger_settlements;


TRUNCATE TABLE warehouse.fact_corporate_receivables;

INSERT INTO warehouse.fact_corporate_receivables (

    corp_transaction_id,
    receivable_settlement_date,
    reference_id,
    store_id,
    receivable_amount,
    currency,
    receivable_account

)

SELECT

    corp_transaction_id,
    receivable_settlement_date::DATE,
    reference_id,
    store_id,
    receivable_amount::NUMERIC(10,2),
    currency,
    receivable_account

FROM staging.corporate_receivables;