CREATE TABLE IF NOT EXISTS warehouse.fact_pos_transactions (
    pos_transaction_id VARCHAR(50) PRIMARY KEY,
    transaction_date DATE,
    store_id VARCHAR(10),
    store_name VARCHAR(100),
    payment_method VARCHAR(50),
    gross_amount NUMERIC(10,2),
    currency VARCHAR(10),
    transaction_status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS warehouse.fact_bank_settlements (
    bank_transaction_id VARCHAR(50) PRIMARY KEY,
    settlement_date DATE,
    reference_id VARCHAR(50),
    store_id VARCHAR(10),
    settled_amount NUMERIC(10,2),
    currency VARCHAR(10),
    bank_account VARCHAR(100)
);