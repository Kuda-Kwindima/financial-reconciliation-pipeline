from datetime import timedelta
from pathlib import Path

import numpy as np
import pandas as pd


np.random.seed(42)

BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)

MONTHS = pd.date_range("2026-01-01", periods=6, freq="MS")
TRANSACTIONS_PER_MONTH = 50_000

STORES = {
    "DR001": {
        "name": "Main Restaurant",
        "min_amount": 20,
        "max_amount": 250,
    },
    "DR002": {
        "name": "Pool Bar",
        "min_amount": 5,
        "max_amount": 80,
    },
    "DR003": {
        "name": "Lobby Lounge",
        "min_amount": 8,
        "max_amount": 120,
    },
}

PAYMENT_METHODS = [
    "Visa",
    "Mastercard",
    "Amex",
    "Cash",
    "Room Charge",
    "Corporate Account",
]

PAYMENT_PROBABILITIES = [0.35, 0.25, 0.10, 0.15, 0.10, 0.05]


def random_date_in_month(month_start: pd.Timestamp) -> pd.Timestamp:
    month_end = month_start + pd.offsets.MonthEnd(0)
    days_in_month = (month_end - month_start).days + 1

    return month_start + timedelta(
        days=int(np.random.randint(0, days_in_month))
    )


def generate_pos_transactions() -> pd.DataFrame:
    records = []
    store_counters = {store_id: 1 for store_id in STORES.keys()}

    for month_start in MONTHS:
        for _ in range(TRANSACTIONS_PER_MONTH):
            store_id = np.random.choice(list(STORES.keys()))
            store = STORES[store_id]

            transaction_number = store_counters[store_id]
            store_counters[store_id] += 1

            pos_transaction_id = f"{store_id}-TXN{transaction_number:06d}"
            transaction_date = random_date_in_month(month_start)

            payment_method = np.random.choice(
                PAYMENT_METHODS,
                p=PAYMENT_PROBABILITIES,
            )

            gross_amount = round(
                np.random.uniform(
                    store["min_amount"],
                    store["max_amount"],
                ),
                2,
            )

            records.append(
                {
                    "pos_transaction_id": pos_transaction_id,
                    "transaction_date": transaction_date.date(),
                    "store_id": store_id,
                    "store_name": store["name"],
                    "payment_method": payment_method,
                    "gross_amount": gross_amount,
                    "currency": "USD",
                    "transaction_status": "Completed",
                }
            )

    return pd.DataFrame(records)


def generate_settlement_records(
    pos_df: pd.DataFrame,
    payment_methods: list[str],
    id_prefix: str,
    reference_column_name: str,
    amount_column_name: str,
    date_column_name: str,
    account_column_name: str,
    account_value: str,
) -> pd.DataFrame:
    records = []
    settlement_counter = 1

    eligible_pos = pos_df[
        pos_df["payment_method"].isin(payment_methods)
    ].copy()

    for _, row in eligible_pos.iterrows():
        issue_type = np.random.choice(
            [
                "matched",
                "missing",
                "amount_mismatch",
                "delayed",
                "duplicate",
            ],
            p=[0.905, 0.04, 0.03, 0.015, 0.01],
        )

        if issue_type == "missing":
            continue

        settlement_delay = int(np.random.randint(1, 3))

        if issue_type == "delayed":
            settlement_delay = int(np.random.randint(4, 10))

        settlement_date = pd.to_datetime(row["transaction_date"]) + timedelta(
            days=settlement_delay
        )

        settled_amount = row["gross_amount"]

        if issue_type == "amount_mismatch":
            difference = round(np.random.uniform(1, 15), 2)
            settled_amount = round(row["gross_amount"] - difference, 2)

        record = {
            f"{id_prefix.lower()}_transaction_id": f"{id_prefix}{settlement_counter:07d}",
            date_column_name: settlement_date.date(),
            reference_column_name: row["pos_transaction_id"],
            "store_id": row["store_id"],
            amount_column_name: settled_amount,
            "currency": "USD",
            account_column_name: account_value,
        }

        records.append(record)
        settlement_counter += 1

        if issue_type == "duplicate":
            duplicate_record = record.copy()
            duplicate_record[
                f"{id_prefix.lower()}_transaction_id"
            ] = f"{id_prefix}{settlement_counter:07d}"

            records.append(duplicate_record)
            settlement_counter += 1

    return pd.DataFrame(records)


def generate_bank_settlements(pos_df: pd.DataFrame) -> pd.DataFrame:
    return generate_settlement_records(
        pos_df=pos_df,
        payment_methods=["Visa", "Mastercard", "Amex"],
        id_prefix="BANK",
        reference_column_name="reference_id",
        amount_column_name="settled_amount",
        date_column_name="settlement_date",
        account_column_name="bank_account",
        account_value="DHG_OPERATING_ACCOUNT",
    )


def generate_cash_deposits(pos_df: pd.DataFrame) -> pd.DataFrame:
    return generate_settlement_records(
        pos_df=pos_df,
        payment_methods=["Cash"],
        id_prefix="CASH",
        reference_column_name="reference_id",
        amount_column_name="deposited_amount",
        date_column_name="deposit_date",
        account_column_name="cash_account",
        account_value="DHG_CASH_CLEARING_ACCOUNT",
    )


def generate_guest_ledger_settlements(pos_df: pd.DataFrame) -> pd.DataFrame:
    return generate_settlement_records(
        pos_df=pos_df,
        payment_methods=["Room Charge"],
        id_prefix="LEDGER",
        reference_column_name="reference_id",
        amount_column_name="ledger_amount",
        date_column_name="ledger_settlement_date",
        account_column_name="ledger_account",
        account_value="DHG_GUEST_LEDGER",
    )


def generate_corporate_receivables(pos_df: pd.DataFrame) -> pd.DataFrame:
    return generate_settlement_records(
        pos_df=pos_df,
        payment_methods=["Corporate Account"],
        id_prefix="CORP",
        reference_column_name="reference_id",
        amount_column_name="receivable_amount",
        date_column_name="receivable_settlement_date",
        account_column_name="receivable_account",
        account_value="DHG_CORPORATE_RECEIVABLES",
    )


def main() -> None:
    print("Generating POS transactions...")
    pos_df = generate_pos_transactions()

    print("Generating bank settlements...")
    bank_df = generate_bank_settlements(pos_df)

    print("Generating cash deposits...")
    cash_df = generate_cash_deposits(pos_df)

    print("Generating guest ledger settlements...")
    ledger_df = generate_guest_ledger_settlements(pos_df)

    print("Generating corporate receivables...")
    corporate_df = generate_corporate_receivables(pos_df)

    output_files = {
        "pos_transactions.csv": pos_df,
        "bank_settlements.csv": bank_df,
        "cash_deposits.csv": cash_df,
        "guest_ledger_settlements.csv": ledger_df,
        "corporate_receivables.csv": corporate_df,
    }

    for file_name, dataframe in output_files.items():
        file_path = RAW_DIR / file_name
        dataframe.to_csv(file_path, index=False)
        print(f"{file_name} saved to: {file_path}")
        print(f"{file_name} rows: {len(dataframe):,}")


if __name__ == "__main__":
    main()