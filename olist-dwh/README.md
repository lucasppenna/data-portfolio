# Olist Data Warehouse

Data warehouse do dataset Olist (e-commerce brasileiro, 2016-2018, Kaggle)
construído em DuckDB, com ingest de 9 CSVs.

## Como rodar

1. Crie e ative o ambiente:

    python -m venv .venv
    .venv\Scripts\Activate.ps1

2. Instale a dependência:

    pip install duckdb

3. Execute o setup:

    python setup_db.py


    ## Dicionário de dados

| Tabela | Linhas | Grão |
|--------|--------|------|
| customers | 99.441 | 1 linha por pedido (customer_id); a pessoa real é o customer_unique_id — 96.096 pessoas, ~3,4% de recorrência |
| geolocation | 1.000.163 | 1 linha por par CEP-coordenada |
| order_items | 112.650 | 1 linha por item de pedido |
| order_payments | 103.886 | 1 linha por pagamento (pedido pode ter mais de 1) |
| order_reviews | 99.224 | 1 linha por avaliação (nem todo pedido tem) |
| orders | 99.441 | 1 linha por pedido |
| products | 32.951 | 1 linha por produto |
| sellers | 3.095 | 1 linha por vendedor |
| category_name | 71 | 1 linha por categoria (tradução PT→EN) |


## Relações entre tabelas

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
