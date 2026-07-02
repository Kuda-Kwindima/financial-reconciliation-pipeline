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


def generate_bank_settlements(pos_df: pd.DataFrame) -> pd.DataFrame:
    bank_records = []
    bank_counter = 1

    card_payment_methods = ["Visa", "Mastercard", "Amex"]

    eligible_pos = pos_df[
        pos_df["payment_method"].isin(card_payment_methods)
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

        settlement_delay = np.random.randint(1, 3)

        if issue_type == "delayed":
            settlement_delay = np.random.randint(4, 10)

        settlement_date = pd.to_datetime(row["transaction_date"]) + timedelta(
            days=int(settlement_delay)
        )

        settled_amount = row["gross_amount"]

        if issue_type == "amount_mismatch":
            difference = round(np.random.uniform(1, 15), 2)
            settled_amount = round(row["gross_amount"] - difference, 2)

        bank_records.append(
            {
                "bank_transaction_id": f"BANK{bank_counter:07d}",
                "settlement_date": settlement_date.date(),
                "reference_id": row["pos_transaction_id"],
                "store_id": row["store_id"],
                "settled_amount": settled_amount,
                "currency": "USD",
                "bank_account": "DHG_OPERATING_ACCOUNT",
            }
        )
        bank_counter += 1

        if issue_type == "duplicate":
            bank_records.append(
                {
                    "bank_transaction_id": f"BANK{bank_counter:07d}",
                    "settlement_date": settlement_date.date(),
                    "reference_id": row["pos_transaction_id"],
                    "store_id": row["store_id"],
                    "settled_amount": settled_amount,
                    "currency": "USD",
                    "bank_account": "DHG_OPERATING_ACCOUNT",
                }
            )
            bank_counter += 1

    unknown_count = int(len(pos_df) * 0.005)

    for _ in range(unknown_count):
        store_id = np.random.choice(list(STORES.keys()))
        store = STORES[store_id]
        random_month = pd.Timestamp(np.random.choice(MONTHS.to_list()))
        settlement_date = random_date_in_month(random_month)

        bank_records.append(
            {
                "bank_transaction_id": f"BANK{bank_counter:07d}",
                "settlement_date": settlement_date.date(),
                "reference_id": f"UNKNOWN-{bank_counter:07d}",
                "store_id": store_id,
                "settled_amount": round(
                    np.random.uniform(
                        store["min_amount"],
                        store["max_amount"],
                    ),
                    2,
                ),
                "currency": "USD",
                "bank_account": "DHG_OPERATING_ACCOUNT",
            }
        )
        bank_counter += 1

    return pd.DataFrame(bank_records)


def main() -> None:
    print("Generating POS transactions...")
    pos_df = generate_pos_transactions()

    print("Generating bank settlements...")
    bank_df = generate_bank_settlements(pos_df)

    pos_path = RAW_DIR / "pos_transactions.csv"
    bank_path = RAW_DIR / "bank_settlements.csv"

    pos_df.to_csv(pos_path, index=False)
    bank_df.to_csv(bank_path, index=False)

    print(f"POS transactions saved to: {pos_path}")
    print(f"Bank settlements saved to: {bank_path}")
    print(f"POS rows: {len(pos_df):,}")
    print(f"Bank rows: {len(bank_df):,}")


if __name__ == "__main__":
    main()