# Financial Transaction Reconciliation & Exception Monitoring Pipeline

## Project Overview

This project is an end-to-end data engineering pipeline that reconciles hospitality POS transactions against multiple settlement channels and produces business-ready reporting outputs for finance teams.

The pipeline simulates a hospitality group with multiple outlets and payment methods, loads raw transaction data into PostgreSQL, transforms it through staging, warehouse, reconciliation, and mart layers, orchestrates the workflow with Prefect, and prepares reporting outputs for Power BI.

## Business Problem

Hospitality finance teams need to verify that sales recorded in the POS system are correctly settled through the appropriate financial channel.

Common reconciliation issues include:

- Missing settlements
- Amount mismatches
- Duplicate settlements
- Delayed settlements

This project helps finance teams identify which transactions require investigation, which payment methods create the most exceptions, and which outlets have the highest reconciliation risk.

## Payment Methods Covered

| POS Payment Method | Settlement Channel |
|---|---|
| Visa | Card / Bank Settlement |
| Mastercard | Card / Bank Settlement |
| Amex | Card / Bank Settlement |
| Cash | Cash Deposit |
| Room Charge | Guest Ledger |
| Corporate Account | Corporate Receivables |

## Tech Stack

- Python
- Pandas
- PostgreSQL
- SQL
- SQLAlchemy
- Docker
- Prefect
- Power BI
- Git / GitHub

## Project Architecture

```text
Synthetic POS & Settlement Data
        ↓
Raw CSV Files
        ↓
PostgreSQL Staging Layer
        ↓
Warehouse Dimensions, Facts & Data-Quality Tables
        ↓
Reconciliation Fact
        ↓
Reporting Marts
        ↓
Power BI Dashboard
```

## Data Layers

### 1. Raw Data

Generated CSV files are stored in:

```text
data/raw/
```

Generated files:

```text
pos_transactions.csv
bank_settlements.csv
cash_deposits.csv
guest_ledger_settlements.csv
corporate_receivables.csv
```

The synthetic data generator intentionally introduces realistic data-quality and reconciliation scenarios, including missing identifiers, invalid values, cancelled transactions, duplicate source records, missing settlements, amount mismatches, duplicate settlements, and delayed settlements.

### 2. Staging Layer

Raw CSV values are loaded into PostgreSQL as text so that source values are preserved before validation and typing.

Each staging row includes lineage fields:

```text
source_file
source_row_number
pipeline_run_id
```

Staging tables:

```text
staging.pos_transactions
staging.bank_settlements
staging.cash_deposits
staging.guest_ledger_settlements
staging.corporate_receivables
```

### 3. Warehouse Layer

The warehouse layer standardizes values, applies data types, enforces business rules, and routes records into accepted, rejected, or excluded tables.

Core transformation pattern:

```text
Normalize → Type → Validate → Route
```

Dimensions:

```text
warehouse.dim_store
warehouse.dim_payment_method
```

Accepted fact tables:

```text
warehouse.fact_pos_transactions
warehouse.fact_bank_settlements
warehouse.fact_cash_deposits
warehouse.fact_guest_ledger_settlements
warehouse.fact_corporate_receivables
```

Data-quality tables:

```text
warehouse.rejected_pos_transactions
warehouse.excluded_pos_transactions
warehouse.rejected_settlements
```

Rejected records contain invalid or incomplete values that cannot safely enter the trusted warehouse. Excluded records are valid enough to retain for audit purposes but fall outside reconciliation scope, such as cancelled transactions or duplicate source records.

### 4. Reconciliation Layer

```text
warehouse.fact_reconciliation_results
```

The reconciliation fact has one row per accepted POS transaction.

Each POS transaction is matched using:

```text
POS transaction ID + expected settlement channel
```

Matching on both fields prevents false matches between card, cash, guest-ledger, and corporate settlement records.

A `LEFT JOIN` is used so that POS transactions remain visible even when no settlement exists.

### 5. Mart Layer

Reporting marts are created for Power BI and finance analysis:

```text
marts.mart_reconciliation_summary
marts.mart_store_reconciliation_performance
marts.mart_payment_method_performance
marts.mart_exception_summary
```

## Reconciliation Logic

Settlement records are standardized across the four settlement channels using `UNION ALL`, preserving duplicates so that duplicate settlement events remain detectable.

The reconciliation logic uses the following priority:

1. `MISSING_SETTLEMENT`
2. `DUPLICATE_SETTLEMENT`
3. `AMOUNT_MISMATCH`
4. `DELAYED_SETTLEMENT`
5. `MATCHED`

| Status | Meaning |
|---|---|
| `MATCHED` | Settlement exists with the correct amount and acceptable timing |
| `MISSING_SETTLEMENT` | No matching settlement record exists |
| `AMOUNT_MISMATCH` | Settlement exists but the value differs from the POS amount |
| `DUPLICATE_SETTLEMENT` | More than one settlement record exists for the same transaction and channel |
| `DELAYED_SETTLEMENT` | Settlement was received more than three days after the POS transaction |

## Final Validated Results

The following figures were validated directly from PostgreSQL staging, warehouse, reconciliation, and reporting-mart tables.

### Data-Quality Accounting

The pipeline processes **301,500 staged POS records**. During warehouse processing, each row is routed to exactly one outcome:

| Warehouse Outcome | Records |
|---|---:|
| Accepted trusted transactions | 297,309 |
| Rejected validation failures | 1,804 |
| Excluded transactions | 2,387 |
| **Total staged POS records** | **301,500** |

The excluded population consists of:

| Exclusion Reason | Records |
|---|---:|
| Duplicate source record | 1,488 |
| Cancelled transaction | 899 |
| **Total excluded records** | **2,387** |

The accepted, rejected, and excluded categories are mutually exclusive and reconcile exactly to the staged input volume.

### Headline Reconciliation Metrics

| Metric | Value |
|---|---:|
| Accepted reconciliation rows | 297,309 |
| Matched transactions | 267,706 |
| Exception transactions | 29,603 |
| Overall match rate | 90.04% |

### Reconciliation Summary

| Status | Transaction Count | Percentage |
|---|---:|---:|
| `MATCHED` | 267,706 | 90.04% |
| `MISSING_SETTLEMENT` | 13,491 | 4.54% |
| `AMOUNT_MISMATCH` | 8,752 | 2.94% |
| `DELAYED_SETTLEMENT` | 4,469 | 1.50% |
| `DUPLICATE_SETTLEMENT` | 2,891 | 0.97% |

Percentages total 99.99% because each category is rounded independently to two decimal places.

### Payment Method Performance

| Payment Method | Settlement Channel | Total Transactions | Matched | Exceptions | Match Rate |
|---|---|---:|---:|---:|---:|
| Visa | CARD | 104,049 | 93,738 | 10,311 | 90.09% |
| Mastercard | CARD | 74,107 | 66,730 | 7,377 | 90.05% |
| Cash | CASH | 44,602 | 40,089 | 4,513 | 89.88% |
| Amex | CARD | 29,900 | 26,898 | 3,002 | 89.96% |
| Room Charge | GUEST_LEDGER | 29,746 | 26,837 | 2,909 | 90.22% |
| Corporate Account | CORPORATE_RECEIVABLE | 14,905 | 13,414 | 1,491 | 90.00% |

Room Charge achieved the highest match rate at 90.22%. Cash had the lowest match rate at 89.88%. Visa produced the largest number of exceptions because it also had the highest transaction volume.

### Store Performance

| Store | Total Transactions | Matched | Exceptions | Match Rate |
|---|---:|---:|---:|---:|
| Pool Bar | 99,269 | 89,425 | 9,844 | 90.08% |
| Main Restaurant | 99,031 | 89,163 | 9,868 | 90.04% |
| Lobby Lounge | 99,009 | 89,118 | 9,891 | 90.01% |

Store performance was consistent across all three outlets, with match rates ranging from 90.01% to 90.08%.

## Power BI Dashboard

The Power BI dashboard is stored in:

```text
dashboard/financial_reconciliation_dashboard.pbix
```

Dashboard pages:

### 1. Executive Overview

- Total reconciled transactions
- Matched transactions
- Exception transactions
- Overall match rate
- Reconciliation status breakdown

### 2. Payment Method Performance

- Payment method summary
- Exceptions by payment method
- Match rate by payment method
- Settlement channel filtering

### 3. Exception Investigation

- Exception type filtering
- Payment method filtering
- Store filtering
- Amount difference by exception type
- Amount difference by store
- Transaction-level investigation table

## Pipeline Execution

### Python Runner

```powershell
python pipeline\run_pipeline.py
```

Execution order:

```text
Generate synthetic source data
        ↓
Load raw CSV files into PostgreSQL staging
        ↓
Execute warehouse, reconciliation, and mart SQL
```

### Prefect Flow

```powershell
python pipeline\prefect_flow.py
```

The Prefect flow wraps the same pipeline stages as observable tasks and stops execution if a dependent stage fails.

## How to Run Locally

### 1. Clone the repository

```powershell
git clone https://github.com/Kuda-Kwindima/financial-reconciliation-pipeline.git
cd financial-reconciliation-pipeline
```

### 2. Create and activate a virtual environment

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### 3. Install dependencies

```powershell
pip install -r requirements.txt
```

### 4. Start PostgreSQL with Docker

```powershell
docker compose up -d
```

Verify the container:

```powershell
docker ps
```

Expected container:

```text
reconciliation_postgres
```

PostgreSQL connection details:

```text
Host: localhost
Port: 5434
Database: reconciliation_db
Username: postgres
Password: postgres
```

### 5. Run the full pipeline

```powershell
python pipeline\run_pipeline.py
```

### 6. Run with Prefect orchestration

```powershell
python pipeline\prefect_flow.py
```

## Main Pipeline Files

| File | Purpose |
|---|---|
| `pipeline/generate_data.py` | Generates reproducible synthetic POS and settlement data |
| `pipeline/load_to_postgres.py` | Loads source CSV files into PostgreSQL staging with lineage |
| `pipeline/sql_runner.py` | Executes SQL scripts in dependency order |
| `pipeline/run_pipeline.py` | Runs the complete pipeline using Python subprocess orchestration |
| `pipeline/prefect_flow.py` | Runs the complete pipeline as Prefect tasks and a Prefect flow |

## SQL Structure

```text
sql/
├── setup/
│   └── create_schemas.sql
├── staging/
│   ├── create_staging_tables.sql
│   └── truncate_staging_tables.sql
├── warehouse/
│   ├── create_warehouse_tables.sql
│   ├── load_warehouse_tables.sql
│   ├── create_reconciliation_results.sql
│   └── load_reconciliation_results.sql
└── marts/
    ├── create_mart_reconciliation_summary.sql
    ├── load_mart_reconciliation_summary.sql
    ├── create_mart_store_reconciliation_performance.sql
    ├── load_mart_store_reconciliation_performance.sql
    ├── create_mart_payment_method_performance.sql
    ├── load_mart_payment_method_performance.sql
    ├── create_mart_exception_summary.sql
    └── load_mart_exception_summary.sql
```

## Project Skills Demonstrated

- End-to-end data pipeline design
- Multi-layer data architecture
- PostgreSQL database modeling
- Staging, warehouse, reconciliation, and mart design
- Source and pipeline-run lineage
- Data normalization and type conversion
- Data-quality routing into accepted, rejected, and excluded records
- Deterministic POS deduplication using window functions
- Cross-channel financial reconciliation
- Exception classification and monitoring
- Python pipeline automation
- Prefect orchestration
- Dockerized PostgreSQL setup
- Power BI-ready reporting models
- Git and GitHub version control

## Future Improvements

- Add dbt for SQL model management, documentation, and testing
- Add automated data-quality and reconciliation tests
- Add a row-accounting audit test that verifies staged rows equal accepted, rejected, and excluded rows after every run
- Add CI/CD validation with GitHub Actions
- Add incremental loading instead of full refresh
- Add production logging and configurable retries
- Deploy the pipeline to Snowflake, Microsoft Fabric, or Azure
- Publish the Power BI report to Power BI Service with scheduled refresh

## Author

Kudakwashe Kwindima  
Data Engineering Portfolio Project
