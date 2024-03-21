{{ config(materialized = 'dummy_col') }}

select * from {{ source('src_table', 'customer') }}
