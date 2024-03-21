{{ config(
        materialized = 'table',
        table_type = 'iceberg',
        external_volume='ICEBERG_EXT_VOL_2024',
        catalog='SNOWFLAKE',
        base_location='') }}

select user_name, user_status from {{ source('dbt_custom', 'my_source') }}