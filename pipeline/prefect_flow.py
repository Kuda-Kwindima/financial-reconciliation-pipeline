import subprocess
import sys

from prefect import flow, task


@task(name="Generate synthetic transaction data")
def generate_data() -> None:
    subprocess.run(
        [sys.executable, "pipeline/generate_data.py"],
        check=True,
    )


@task(name="Load CSV files to PostgreSQL staging")
def load_to_staging() -> None:
    subprocess.run(
        [sys.executable, "pipeline/load_to_postgres.py"],
        check=True,
    )


@task(name="Refresh warehouse and mart tables")
def refresh_warehouse_and_marts() -> None:
    subprocess.run(
        [sys.executable, "pipeline/sql_runner.py"],
        check=True,
    )


@flow(name="financial-reconciliation-pipeline")
def reconciliation_pipeline() -> None:
    generate_data()
    load_to_staging()
    refresh_warehouse_and_marts()


if __name__ == "__main__":
    reconciliation_pipeline()