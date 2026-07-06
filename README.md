# Financial Transaction Reconciliation & Exception Monitoring Pipeline

## Project Overview

This project is an end-to-end data engineering pipeline that reconciles hospitality POS transactions against multiple settlement channels and produces business-ready reporting outputs for finance teams.

The pipeline simulates a hospitality group with multiple outlets and payment methods, loads raw transaction data into PostgreSQL, transforms it through staging, warehouse, and mart layers, orchestrates the workflow with Prefect, and visualizes reconciliation performance in Power BI.

## Business Problem

Hospitality finance teams need to verify that sales recorded in the POS system are correctly settled through the correct financial channels.

Common reconciliation issues include:

- Missing settlements
- Amount mismatches
- Duplicate settlements
- Delayed settlements

This project helps finance teams identify which transactions require investigation, which payment methods create the most exceptions, and which outlets have the highest reconciliation risk.

## Payment Methods Covered

The project reconciles multiple POS payment methods across different settlement channels.

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
- Docker
- SQL
- SQLAlchemy
- Prefect
- Power BI
- Git / GitHub

## Project Architecture

```text
Synthetic POS & Settlement Data
        ↓
Raw CSV Files
        ↓
PostgreSQL Staging Tables
        ↓
Warehouse Fact Tables
        ↓
Reconciliation Results
        ↓
Reporting Marts
        ↓
Power BI Dashboard
```

## Data Layers

### 1. Raw Data

Generated CSV files are stored locally in:

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

### 2. Staging Layer

Raw CSV data is loaded into PostgreSQL staging tables:

```text
staging.pos_transactions
staging.bank_settlements
staging.cash_deposits
staging.guest_ledger_settlements
staging.corporate_receivables
```

### 3. Warehouse Layer

Warehouse tables standardize data types and store trusted transaction-level records:

```text
warehouse.fact_pos_transactions
warehouse.fact_bank_settlements
warehouse.fact_cash_deposits
warehouse.fact_guest_ledger_settlements
warehouse.fact_corporate_receivables
warehouse.fact_reconciliation_results
```

### 4. Mart Layer

Reporting marts are created for Power BI:

```text
marts.mart_reconciliation_summary
marts.mart_store_reconciliation_performance
marts.mart_payment_method_performance
marts.mart_exception_summary
```

## Reconciliation Logic

The reconciliation engine compares each POS transaction against the expected settlement channel.

Statuses generated:

| Status | Meaning |
|---|---|
| MATCHED | POS transaction has a matching settlement record with correct amount and timing |
| MISSING_SETTLEMENT | POS transaction has no matching settlement record |
| AMOUNT_MISMATCH | Settlement exists but the amount differs from the POS amount |
| DUPLICATE_SETTLEMENT | More than one settlement record exists for the same POS transaction |
| DELAYED_SETTLEMENT | Settlement exists but was received more than 3 days after the POS transaction |

## Key Results

Current generated dataset:

| Metric | Value |
|---|---:|
| POS transactions | 300,000 |
| Reconciliation result rows | 302,950 |
| Matched transactions | 271,429 |
| Exception rows | 31,521 |
| Overall match rate | 89.60% |

Reconciliation summary:

| Status | Transaction Count | Percentage |
|---|---:|---:|
| MATCHED | 271,429 | 89.60% |
| MISSING_SETTLEMENT | 12,013 | 3.97% |
| AMOUNT_MISMATCH | 9,070 | 2.99% |
| DUPLICATE_SETTLEMENT | 5,900 | 1.95% |
| DELAYED_SETTLEMENT | 4,538 | 1.50% |

Payment method performance:

| Payment Method | Settlement Channel | Total Transactions | Matched Transactions | Exception Transactions | Match Rate |
|---|---|---:|---:|---:|---:|
| Visa | CARD | 106,028 | 95,077 | 10,951 | 89.67% |
| Mastercard | CARD | 75,500 | 67,633 | 7,867 | 89.58% |
| Cash | CASH | 45,421 | 40,634 | 4,787 | 89.46% |
| Amex | CARD | 30,510 | 27,265 | 3,245 | 89.36% |
| Room Charge | GUEST_LEDGER | 30,316 | 27,225 | 3,091 | 89.80% |
| Corporate Account | CORPORATE_RECEIVABLE | 15,175 | 13,595 | 1,580 | 89.59% |

## Power BI Dashboard

The Power BI dashboard is stored in:

```text
dashboard/financial_reconciliation_dashboard.pbix
```

Dashboard pages:

### 1. Executive Overview

Shows overall reconciliation health:

- Total reconciled transactions
- Matched transactions
- Exception transactions
- Overall match rate
- Reconciliation status breakdown

### 2. Payment Method Performance

Shows reconciliation performance by payment method and settlement channel:

- Payment method summary table
- Exceptions by payment method
- Match rate by payment method
- Settlement channel slicer

### 3. Exception Investigation

Shows transaction-level exceptions requiring finance review:

- Exception type slicer
- Payment method slicer
- Store slicer
- Exception amount difference by type
- Exception amount difference by store
- Detailed transaction-level exception table

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

Verify the container is running:

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

This runs:

```text
Generate synthetic data
Load raw CSV files to PostgreSQL staging
Refresh warehouse and mart tables
```

### 6. Run with Prefect orchestration

```powershell
python pipeline\prefect_flow.py
```

The Prefect flow orchestrates:

```text
Generate synthetic transaction data
Load CSV files to PostgreSQL staging
Refresh warehouse and mart tables
```

## Main Pipeline Files

| File | Purpose |
|---|---|
| `pipeline/generate_data.py` | Generates synthetic POS and settlement data |
| `pipeline/load_to_postgres.py` | Loads raw CSV files into PostgreSQL staging tables |
| `pipeline/sql_runner.py` | Runs SQL scripts in the correct order |
| `pipeline/run_pipeline.py` | Runs the full pipeline using Python |
| `pipeline/prefect_flow.py` | Runs the full pipeline with Prefect orchestration |

## SQL Structure

```text
sql/
├── setup/
│   └── create_schemas.sql
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

This project demonstrates:

- End-to-end data pipeline design
- PostgreSQL database modeling
- Dockerized database setup
- Multi-layer data architecture
- Staging, warehouse, and mart design
- SQL transformation logic
- Data reconciliation rules
- Exception monitoring
- Python pipeline automation
- Prefect orchestration
- Power BI reporting
- Git/GitHub version control

## Future Improvements

Potential enhancements:

- Add dbt for SQL model management and testing
- Add automated data quality tests
- Add CI/CD validation with GitHub Actions
- Deploy pipeline to Microsoft Fabric or Azure
- Add incremental loading instead of full refresh
- Add Power BI Service publishing and scheduled refresh

## Author

Kudakwashe Kwindima  
Data Engineering Portfolio Project
