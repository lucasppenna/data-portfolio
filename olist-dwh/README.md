# Olist Data Warehouse

A data warehouse built on the Olist Brazilian e-commerce dataset (2016–2018, Kaggle), using dbt and DuckDB, with ingestion of 9 CSV files.

## Overview

This project builds a small analytics warehouse on the Brazilian e-commerce
dataset from Olist (2016–2018), using dbt and DuckDB.

**Layers**
- **Staging** (`models/staging/`): one model per source table, with an
  explicit column list, date casts and documented tests.
  - `stg_orders`
  - `stg_order_items`: incremental, with a 7-day lookback on `shipping_limit_date`
  - `stg_order_payments`
- **Marts** (`models/marts/`): `fct_orders`, one row per order, with payment
  and item totals and data quality flags.

**Data quality**
- A manual scorecard of referential integrity comes first (Data Quality Audit below).
  Each check was then automated as a dbt test.
- Column tests (not null, unique, accepted values, relationships) are declared
  in each model's `.yml` file. The schema files document the column lists and
  tests; they do not enforce a dbt contract.
- Composite keys are checked by singular tests: `assert_order_items_unique_key`
  and `assert_order_payments_unique_key`.
- Known gap: 3 invoiced or shipped orders have no items. `assert_orders_have_items`
  reports them with `severity: warn`, so the pipeline shows the gap without failing.

**CI:** every pull request runs `dbt build` in GitHub Actions. The workflow
downloads the dataset from Kaggle, builds the database and runs the models and tests.

## How to run

1. Download the Olist Brazilian E-Commerce dataset from Kaggle and place the
   9 CSV files in `olist-dwh/data/`.

2. Create and activate a virtual environment, then install the dependencies:

       python -m venv .venv
       .venv\Scripts\Activate.ps1
       pip install -r requirements.txt

3. Build the DuckDB database from the CSVs. Run this from `olist-dwh/`:

       python setup_db.py

   This creates `olist-dwh/olist.dwh`.

4. Configure the dbt profile in `~/.dbt/profiles.yml` (on Windows,
   `C:\Users\<you>\.dbt\profiles.yml`):

       olist_dwh:
         outputs:
           dev:
             type: duckdb
             path: ../olist.dwh
             threads: 4
         target: dev

   The path is relative to the dbt project folder, `olist-dwh/olist_dwh/`.

5. Build and test the project. Run this from `olist-dwh/olist_dwh/`:

       dbt build

   **Expected result:** one intentional failure, `assert_orders_have_items`,
   which returns 3 orders in `invoiced` or `shipped` status with no items.
   It documents a known gap in the source data (see the Data Quality Audit).


## Data dictionary

| Table | Rows | Grain |
|--------|--------|------|
| customers | 99.441 | 1 row per order (customer_id); the real person is customer_unique_id — 96.096 people, ~3.4% repeat rate |
| geolocation | 1.000.163 | 1 row per zip code–coordinate pair |
| order_items | 112.650 | 1 row per order item |
| order_payments | 103.886 | 1 row per payment (an order can have more than one) |
| order_reviews | 99.224 | 1 row per review (not every order has one) |
| orders | 99.441 | 1 row per order |
| products | 32.951 | 1 row per product |
| sellers | 3.095 | 1 row per seller |
| category_name | 71 | 1 row per category (PT→EN translation) |


## Table relationships

- `orders.customer_id` → `customers.customer_id`
- `order_items.order_id` → `orders.order_id`
- `order_items.product_id` → `products.product_id`
- `order_items.seller_id` → `sellers.seller_id`
- `order_payments.order_id` → `orders.order_id`
- `order_reviews.order_id` → `orders.order_id`
- `products.product_category_name` →  `category_name.product_category_name`


## Business Questions Answered

### Q1 — Which states have the slowest average delivery time?

Top 10 states by average delivery time (in days), for delivered orders only,
excluding states with fewer than 50 delivered orders.

| State | Delivered Orders | Avg Delivery (days) |
|-------|-----------------:|--------------------:|
| AP    |               67 |               27.18 |
| AM    |              145 |               26.36 |
| AL    |              397 |               24.50 |
| PA    |              946 |               23.73 |
| MA    |              717 |               21.51 |
| SE    |              335 |               21.46 |
| CE    |            1,279 |               21.20 |
| AC    |               80 |               21.00 |
| PB    |              517 |               20.39 |
| PI    |              476 |               19.39 |

**Finding:** all 10 slowest states are in the North and Northeast regions,
with Amazonian states (AP, AM) at the top — consistent with long distances
from the Southeast hubs and complex logistics.

### Q2 — Which states have the highest late-delivery rate?

Percentage of delivered orders that arrived after the estimated delivery date
(late = delivered strictly after the estimate), states with 50+ orders, top 5.

| State | Delivered Orders | Late Rate (%) |
|-------|-----------------:|--------------:|
| AL    |              397 |         23.93 |
| MA    |              717 |         19.67 |
| PI    |              476 |         15.97 |
| CE    |            1,279 |         15.32 |
| SE    |              335 |         15.22 |

**Finding:** slowest is not the same as latest. AP and AM lead on delivery
*time* but do not appear in the top 5 on *late rate* — their estimates seem
calibrated for distance. AL, by contrast, is not among the slowest in days
but breaks its promise most often (~1 in 4 orders late), suggesting an
optimistic estimate relative to local operational capacity.

**Data quality note:** verified that `order_payments` can contain multiple
rows per order (split payments — e.g., card + voucher, or installments).
`sum(payment_value)` aggregates all payment rows, capturing the total paid
per order.

**Cohort insight:** monthly retention drops to ~0.5% in month 1 and
halves again by month 2. Olist is structurally an acquisition-driven,
one-purchase marketplace — retention is not the growth lever here.
Recent cohorts show fewer steps due to the dataset cutoff (Oct 2018).


**Cross-validation:** new + returning revenue per month reconciles
with the monthly revenue trend from 02_revenue_analytics.sql.



## Day 5 — Data Quality Audit (`04_data_quality_audit.sql`)

**Goal:** audit referential integrity across the Olist star schema
before modeling it in dbt. Every check is a hand-written version of
what `dbt test` will automate in week 2.

### Method
- **Anti-joins** (`left join ... where right.key is null`) to find
  orphans in each relationship
- **Probe before verdict:** orphan counts alone are meaningless —
  each check was investigated by status/category to classify severity
  before writing the scorecard

### Findings

| Check | Orphans | Status | Notes |
|---|---|---|---|
| orders_without_items | 775 | pass_with_notes | 772 expected (canceled/unavailable/created orders never reached item assignment). **3 true anomalies**: invoiced/shipped orders with no items — likely ingestion failures |
| products_without_translation | 623 | review | 610 products with NULL category + 13 categories missing an English translation. Coverage gap, not integrity failure |
| orders_without_customer | 0 | pass | |
| payments_without_order | 0 | pass | |
| reviews_without_order | 0 | pass | |

### Verdict
Referential integrity is solid (4 of 5 relationships fully intact,
including orders ↔ payments in both directions). Remaining issues are
coverage gaps, not blocking risks for modeling.

**Cross-check:** the one delivered order with no payment record found
in the revenue analysis (Day 4) is consistent with this audit — the
orders ↔ payments relation holds from the payment side.

**Severity principle:** a scorecard that classifies by raw counts
would flag a healthy relationship as "fail". Severity must come from
investigation, not from the number alone.

## Ticket evolution (year over year)

This analysis tracks the average value of paid orders by month, compared with the same month of the prior year. The query lives in [olist_dwh/analyses/ticket_evolution_yoy.sql](olist_dwh/analyses/ticket_evolution_yoy.sql).

To avoid distortion from small samples, it only includes months with at least 770 paid orders, both in the month analyzed and in the same month of the prior year. The threshold comes from the standard error of the mean: with a standard deviation of about R$ 222 per order, 770 orders keep the error below 5% of the average ticket.

From January to August 2018, paid order volume grew between 50% and 809% compared with the same months of 2017, decelerating over the period. The average ticket fell between 4% and 11% from January to April 2018, and rose between 1% and 15% from May to August.

The analysis covers only one year of comparison and does not identify the cause of the change in ticket.
