from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text


BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"

DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_HOST = "localhost"
DB_PORT = "5434"
DB_NAME = "reconciliation_db"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)


def create_schemas() -> None:
    with engine.begin() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS staging;"))
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS warehouse;"))
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS marts;"))


def load_csv_to_staging(file_name: str, table_name: str) -> None:
    file_path = RAW_DIR / file_name

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    df = pd.read_csv(file_path)

    df.to_sql(
        name=table_name,
        con=engine,
        schema="staging",
        if_exists="replace",
        index=False,
        chunksize=10_000,
    )

    print(f"Loaded {len(df):,} rows into staging.{table_name}")


def main() -> None:
    create_schemas()

    load_csv_to_staging(
        file_name="pos_transactions.csv",
        table_name="pos_transactions",
    )

    load_csv_to_staging(
        file_name="bank_settlements.csv",
        table_name="bank_settlements",
    )

    print("Staging load complete.")


if __name__ == "__main__":
    main()