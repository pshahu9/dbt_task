with custo as(
    select * from {{ source('ext_table', 'dummy_two') }}
),

final as(
    select
        *
    from    
        custo
)

select * from final