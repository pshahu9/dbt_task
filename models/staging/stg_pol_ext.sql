with pol as (
    select * from {{ source('ext_table', 'stg_policy_ext') }}
),

final as(
    select * from pol
)

select * from final