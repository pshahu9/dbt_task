{% macro select_macro() %}

Select * from {{ ref('my_first_dbt_model') }}

{% endmacro %}