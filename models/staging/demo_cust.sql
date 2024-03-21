{{ config(materialized = 'iceberg') }}

select * from {{ source('src_table', 'customer') }} limit 5
