-- stg_orders: staging da tabela bruta orders
-- Objetivo: limpar a fonte para consumo na camada mart
-- Passos:
--   1. Renomear colunas para snake_case limpo
--   2. Castar datas (purchase, approved, delivered) para TIMESTAMP com TRY_CAST
--   3. Manter order_status como está (validação vem depois no dbt test)
-- Fonte: tabela orders do banco olist.dwh

select
order_id,
customer_id,
order_status,
TRY_CAST(order_purchase_timestamp as TIMESTAMP) as order_purchase_timestamp,
TRY_CAST(order_approved_at as TIMESTAMP) as order_approved_at,
TRY_CAST(order_delivered_carrier_date as TIMESTAMP) as order_delivered_carrier_date,
TRY_CAST(order_delivered_customer_date as TIMESTAMP) as order_delivered_customer_date,
TRY_CAST(order_estimated_delivery_date as TIMESTAMP) as order_estimated_delivery_date


from orders