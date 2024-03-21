{{ 
    config(materialized='dummy_col') 
}}

with cust as(
    select * from {{ source('src_table', 'customer') }}
),

final as(
    select
        *
    from    
        cust
)

select * from final