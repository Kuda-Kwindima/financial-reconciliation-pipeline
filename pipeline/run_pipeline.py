import subprocess
import sys
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[1]


def run_step(step_name: str, script_path: Path) -> None:
    print(f"\nStarting: {step_name}")

    subprocess.run(
        [sys.executable, str(script_path)],
        check=True,
        cwd=BASE_DIR,
    )

    print(f"Completed: {step_name}")


def main() -> None:
    run_step(
        "Generate synthetic data",
        BASE_DIR / "pipeline" / "generate_data.py",
    )

    run_step(
        "Load raw CSVs to PostgreSQL staging",
        BASE_DIR / "pipeline" / "load_to_postgres.py",
    )

    run_step(
        "Refresh warehouse and marts",
        BASE_DIR / "pipeline" / "sql_runner.py",
    )

    print("\nFull pipeline completed successfully.")


if __name__ == "__main__":
    main()