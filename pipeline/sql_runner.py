import os
from pathlib import Path

from sqlalchemy import URL, create_engine, text


DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5434"))
DB_NAME = os.getenv("DB_NAME", "reconciliation_db")

BASE_DIR = Path(__file__).resolve().parents[1]


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

    with open(sql_path, "r", encoding="utf-8") as file:
        sql_text = file.read()

    engine = get_engine()

    with engine.begin() as connection:
        connection.execute(text(sql_text))

    print(f"Executed: {sql_file_path}")


def main() -> None:
    sql_files = [
        "sql/setup/create_schemas.sql",
        "sql/warehouse/create_warehouse_tables.sql",
        "sql/warehouse/load_warehouse_tables.sql",
        "sql/warehouse/create_reconciliation_results.sql",
        "sql/warehouse/load_reconciliation_results.sql",
        "sql/marts/create_mart_reconciliation_summary.sql",
        "sql/marts/create_mart_store_reconciliation_performance.sql",
        "sql/marts/create_mart_exception_summary.sql",
        "sql/marts/create_mart_payment_method_performance.sql",
        "sql/marts/load_mart_reconciliation_summary.sql",
        "sql/marts/load_mart_store_reconciliation_performance.sql",
        "sql/marts/load_mart_exception_summary.sql",
        "sql/marts/load_mart_payment_method_performance.sql",
    ]

    for sql_file in sql_files:
        run_sql_file(sql_file)

    print("\nWarehouse and mart refresh complete.")


if __name__ == "__main__":
    main()