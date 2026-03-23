# Payment Transaction Analytics System (Simulated Data)

## Background & Context
This project replicates a real world payment analytics workflow similar to what a data analyst does in a payments/fintech environment.  
To protect commercial confidentiality, all data used in this project is fully simulated while preserving realistic business logic, data volumes, and reporting structures.


## Objective:
To simulate the daily data operations of a payment provider and build SQL-driven analyses and dashboards that uncover insights on:

- Merchant performance
- Transaction trends
- Payment method profitability
- Retention and churn
- Risk and anomaly detection

This will demonstrate end to end SQL capability from schema design to advanced queries, mirroring the type of analytics done by a Payments Data Analyst or Business Intelligence Analyst.


## Project Overview
The system models merchant payment activity across Australia, including:
- Merchants across multiple industries and states
- Different pricing models (SmartCharge and Simple Flat Rate)
- Merchant tiers (Silver, Gold, Platinum)
- Physical payment terminals
- High-volume transaction-level data

The dataset is designed to reflect realistic fintech reporting and analytics use cases.

## Data Volume
- ~20,000 merchants  
- ~30,000 terminals  
- 1,000,000+ transactions  
- Monthly reporting cadence  

## Data Model
### Core Tables
- `merchants`
- `terminals`
- `price_profiles`
- `payment_methods`
- `transactions`

These tables represent raw operational data similar to what exists in a real payment processing system.

### Analytics Tables
- `merchant_monthly_profitability`

This derived table aggregates transaction-level data into monthly merchant profitability metrics to support reporting and performance analysis.

## Monthly Reporting Workflow
In the real environment, merchant profitability was reviewed on a monthly basis.  
This project mirrors that workflow by aggregating transaction data into monthly metrics using SQL.

The same aggregation logic is designed to be executed each month using the most recent completed calendar period.

## Data Privacy
All data in this repository is synthetic and generated programmatically.  
No real merchant, customer, or financial data has been used or exposed.

## Tools & Skills Demonstrated
- PostgreSQL
- SQL (joins, aggregations, date handling)
- Data modeling & schema design
- Python (data generation & ingestion)
- Analytics workflow design
- Payment industry domain knowledge

## Project Status
This repository currently focuses on system design, data generation, and reporting foundations.  
Additional analytical queries and insights will be added as the project evolves.
