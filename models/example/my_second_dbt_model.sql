{{ config(
        materialized = 'iceberg_dynamic',
        external_volume='ICEBERG_EXT_VOL_2024',
        catalog='SNOWFLAKE',
        base_location='') }}

select *
from {{ ref('my_first_dbt_model') }}
where id = 1
