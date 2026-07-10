import os
from pathlib import Path

import pandas as pd
from sqlalchemy import URL, create_engine, text


DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5434"))
DB_NAME = os.getenv("DB_NAME", "reconciliation_db")

BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"


def get_engine():
    connection_url = URL.create(
        drivername="postgresql+psycopg2",
        username=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
    )

    return create_engine(connection_url)


def run_sql_file(sql_file_path: str) -> None:
    sql_path = BASE_DIR / sql_file_path

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    with open(sql_path, "r", encoding="utf-8-sig") as file:
        sql_text = file.read()

    engine = get_engine()

    with engine.begin() as connection:
        connection.execute(text(sql_text))

    print(f"Executed: {sql_file_path}")


def load_csv_to_postgres(file_name: str, table_name: str) -> None:
    file_path = RAW_DIR / file_name

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    df = pd.read_csv(file_path)

    engine = get_engine()

    df.to_sql(
        name=table_name,
        con=engine,
        schema="staging",
        if_exists="append",
        index=False,
        chunksize=10_000,
    )

    print(f"Loaded {len(df):,} rows into staging.{table_name}")


def main() -> None:
    run_sql_file("sql/staging/create_staging_tables.sql")
    run_sql_file("sql/staging/truncate_staging_tables.sql")

    files_to_load = {
        "pos_transactions.csv": "pos_transactions",
        "bank_settlements.csv": "bank_settlements",
        "cash_deposits.csv": "cash_deposits",
        "guest_ledger_settlements.csv": "guest_ledger_settlements",
        "corporate_receivables.csv": "corporate_receivables",
    }

    for file_name, table_name in files_to_load.items():
        load_csv_to_postgres(file_name, table_name)

    print("Staging load complete.")


if __name__ == "__main__":
    main()
