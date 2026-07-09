import subprocess
import sys
from pathlib import Path

from prefect import flow, task


BASE_DIR = Path(__file__).resolve().parents[1]


def run_script(script_path: Path) -> None:
    subprocess.run(
        [sys.executable, str(script_path)],
        check=True,
        cwd=BASE_DIR,
    )


@task(name="Generate synthetic transaction data")
def generate_data() -> None:
    run_script(BASE_DIR / "pipeline" / "generate_data.py")


@task(name="Load CSV files to PostgreSQL staging")
def load_to_staging() -> None:
    run_script(BASE_DIR / "pipeline" / "load_to_postgres.py")


@task(name="Refresh warehouse and mart tables")
def refresh_warehouse_and_marts() -> None:
    run_script(BASE_DIR / "pipeline" / "sql_runner.py")


@flow(name="financial-reconciliation-pipeline")
def reconciliation_pipeline() -> None:
    generate_data()
    load_to_staging()
    refresh_warehouse_and_marts()


if __name__ == "__main__":
    reconciliation_pipeline()