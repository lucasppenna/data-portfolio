{% macro safe_timestamp(column_name) %}
    TRY_CAST({{ column_name }} as TIMESTAMP)
{% endmacro %}
