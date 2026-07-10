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
    store_counters = {store_id: 1 for store_id in STORES}

    for month_start in MONTHS:
        for _ in range(TRANSACTIONS_PER_MONTH):
            store_id = np.random.choice(list(STORES.keys()))
            store = STORES[store_id]

            transaction_number = store_counters[store_id]
            store_counters[store_id] += 1

            pos_transaction_id = (
                f"{store_id}-TXN{transaction_number:06d}"
            )

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

        settlement_date = (
            pd.to_datetime(row["transaction_date"])
            + timedelta(days=settlement_delay)
        )

        settled_amount = row["gross_amount"]

        if issue_type == "amount_mismatch":
            difference = round(np.random.uniform(1, 15), 2)
            settled_amount = round(
                row["gross_amount"] - difference,
                2,
            )

        transaction_id_column = (
            f"{id_prefix.lower()}_transaction_id"
        )

        record = {
            transaction_id_column: (
                f"{id_prefix}{settlement_counter:07d}"
            ),
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
            duplicate_record[transaction_id_column] = (
                f"{id_prefix}{settlement_counter:07d}"
            )

            records.append(duplicate_record)
            settlement_counter += 1

    return pd.DataFrame(records)


def generate_bank_settlements(
    pos_df: pd.DataFrame,
) -> pd.DataFrame:
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


def generate_cash_deposits(
    pos_df: pd.DataFrame,
) -> pd.DataFrame:
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


def generate_guest_ledger_settlements(
    pos_df: pd.DataFrame,
) -> pd.DataFrame:
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


def generate_corporate_receivables(
    pos_df: pd.DataFrame,
) -> pd.DataFrame:
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


def sample_indices(
    df: pd.DataFrame,
    fraction: float,
) -> pd.Index:
    sample_size = max(1, int(len(df) * fraction))

    return df.sample(
        n=sample_size,
        random_state=int(np.random.randint(0, 1_000_000)),
    ).index


def inject_pos_data_quality_issues(
    pos_df: pd.DataFrame,
) -> pd.DataFrame:
    dirty_df = pos_df.copy()

    text_columns = [
        "pos_transaction_id",
        "transaction_date",
        "store_id",
        "store_name",
        "payment_method",
        "gross_amount",
        "currency",
        "transaction_status",
    ]

    dirty_df[text_columns] = dirty_df[text_columns].astype(str)

    payment_indices = sample_indices(dirty_df, 0.01)

    payment_variants = {
        "Visa": " visa card ",
        "Mastercard": "MASTERCARD ",
        "Amex": " amex",
        "Cash": " cash ",
        "Room Charge": "ROOM CHARGE",
        "Corporate Account": " corporate account ",
    }

    dirty_df.loc[payment_indices, "payment_method"] = (
        dirty_df.loc[payment_indices, "payment_method"]
        .map(payment_variants)
        .fillna(dirty_df.loc[payment_indices, "payment_method"])
    )

    store_indices = sample_indices(dirty_df, 0.005)

    dirty_df.loc[store_indices, "store_id"] = (
        dirty_df.loc[store_indices, "store_id"]
        .str.lower()
        .map(lambda value: f" {value} ")
    )

    currency_indices = sample_indices(dirty_df, 0.005)
    dirty_df.loc[currency_indices, "currency"] = " usd "

    formatted_amount_indices = sample_indices(dirty_df, 0.005)

    dirty_df.loc[
        formatted_amount_indices,
        "gross_amount",
    ] = (
        dirty_df.loc[
            formatted_amount_indices,
            "gross_amount",
        ]
        .astype(float)
        .map(lambda value: f"${value:,.2f}")
    )

    invalid_amount_indices = sample_indices(dirty_df, 0.002)

    dirty_df.loc[
        invalid_amount_indices,
        "gross_amount",
    ] = "INVALID_AMOUNT"

    invalid_date_indices = sample_indices(dirty_df, 0.002)

    dirty_df.loc[
        invalid_date_indices,
        "transaction_date",
    ] = "NOT_A_DATE"

    invalid_store_indices = sample_indices(dirty_df, 0.001)

    dirty_df.loc[
        invalid_store_indices,
        "store_id",
    ] = "XX999"

    missing_id_indices = sample_indices(dirty_df, 0.001)

    dirty_df.loc[
        missing_id_indices,
        "pos_transaction_id",
    ] = ""

    cancelled_indices = sample_indices(dirty_df, 0.003)

    dirty_df.loc[
        cancelled_indices,
        "transaction_status",
    ] = " cancelled "

    duplicate_indices = sample_indices(dirty_df, 0.005)
    duplicate_rows = dirty_df.loc[duplicate_indices].copy()

    dirty_df = pd.concat(
        [dirty_df, duplicate_rows],
        ignore_index=True,
    )

    return dirty_df


def inject_settlement_data_quality_issues(
    settlement_df: pd.DataFrame,
    amount_column: str,
    date_column: str,
) -> pd.DataFrame:
    dirty_df = settlement_df.copy()
    dirty_df = dirty_df.astype(str)

    reference_indices = sample_indices(dirty_df, 0.005)

    dirty_df.loc[
        reference_indices,
        "reference_id",
    ] = (
        dirty_df.loc[reference_indices, "reference_id"]
        .str.lower()
        .map(lambda value: f" {value} ")
    )

    currency_indices = sample_indices(dirty_df, 0.005)
    dirty_df.loc[currency_indices, "currency"] = " usd "

    formatted_amount_indices = sample_indices(dirty_df, 0.005)

    dirty_df.loc[
        formatted_amount_indices,
        amount_column,
    ] = (
        dirty_df.loc[
            formatted_amount_indices,
            amount_column,
        ]
        .astype(float)
        .map(lambda value: f"${value:,.2f}")
    )

    invalid_amount_indices = sample_indices(dirty_df, 0.002)

    dirty_df.loc[
        invalid_amount_indices,
        amount_column,
    ] = "INVALID_AMOUNT"

    invalid_date_indices = sample_indices(dirty_df, 0.002)

    dirty_df.loc[
        invalid_date_indices,
        date_column,
    ] = "NOT_A_DATE"

    missing_reference_indices = sample_indices(dirty_df, 0.001)

    dirty_df.loc[
        missing_reference_indices,
        "reference_id",
    ] = ""

    return dirty_df


def main() -> None:
    print("Generating clean POS transactions...")
    clean_pos_df = generate_pos_transactions()

    print("Generating clean bank settlements...")
    clean_bank_df = generate_bank_settlements(clean_pos_df)

    print("Generating clean cash deposits...")
    clean_cash_df = generate_cash_deposits(clean_pos_df)

    print("Generating clean guest ledger settlements...")
    clean_ledger_df = generate_guest_ledger_settlements(
        clean_pos_df
    )

    print("Generating clean corporate receivables...")
    clean_corporate_df = generate_corporate_receivables(
        clean_pos_df
    )

    print("Injecting controlled source data-quality issues...")

    raw_pos_df = inject_pos_data_quality_issues(clean_pos_df)

    raw_bank_df = inject_settlement_data_quality_issues(
        settlement_df=clean_bank_df,
        amount_column="settled_amount",
        date_column="settlement_date",
    )

    raw_cash_df = inject_settlement_data_quality_issues(
        settlement_df=clean_cash_df,
        amount_column="deposited_amount",
        date_column="deposit_date",
    )

    raw_ledger_df = inject_settlement_data_quality_issues(
        settlement_df=clean_ledger_df,
        amount_column="ledger_amount",
        date_column="ledger_settlement_date",
    )

    raw_corporate_df = inject_settlement_data_quality_issues(
        settlement_df=clean_corporate_df,
        amount_column="receivable_amount",
        date_column="receivable_settlement_date",
    )

    output_files = {
        "pos_transactions.csv": raw_pos_df,
        "bank_settlements.csv": raw_bank_df,
        "cash_deposits.csv": raw_cash_df,
        "guest_ledger_settlements.csv": raw_ledger_df,
        "corporate_receivables.csv": raw_corporate_df,
    }

    for file_name, dataframe in output_files.items():
        file_path = RAW_DIR / file_name
        dataframe.to_csv(file_path, index=False)

        print(f"{file_name} saved to: {file_path}")
        print(f"{file_name} rows: {len(dataframe):,}")


if __name__ == "__main__":
    main()