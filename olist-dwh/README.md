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



