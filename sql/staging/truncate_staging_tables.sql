TRUNCATE TABLE
    staging.pos_transactions,
    staging.bank_settlements,
    staging.cash_deposits,
    staging.guest_ledger_settlements,
    staging.corporate_receivables
RESTART IDENTITY;
