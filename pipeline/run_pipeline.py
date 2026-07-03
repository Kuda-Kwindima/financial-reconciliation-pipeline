import subprocess
import sys


def run_step(step_name: str, command: list[str]) -> None:
    print(f"\nStarting: {step_name}")

    subprocess.run(
        command,
        check=True,
    )

    print(f"Completed: {step_name}")


def main() -> None:
    run_step(
        "Generate synthetic data",
        [sys.executable, "pipeline/generate_data.py"],
    )

    run_step(
        "Load raw CSVs to PostgreSQL staging",
        [sys.executable, "pipeline/load_to_postgres.py"],
    )

    run_step(
        "Refresh warehouse and marts",
        [sys.executable, "pipeline/sql_runner.py"],
    )

    print("\nFull pipeline completed successfully.")


if __name__ == "__main__":
    main()