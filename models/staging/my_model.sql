{{ config(
    materialized='iceberg'
) }}

select user_name, user_status from {{ source('dbt_custom', 'my_source') }}