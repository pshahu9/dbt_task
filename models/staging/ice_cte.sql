{{ config(
        materialized = 'iceberg_dynamic',
        external_volume ='ICEBERG_EXT_VOL_2024',
        catalog ='SNOWFLAKE',
        base_location ='',
        alias = 'ice_table',
        tags = ["ice_tag"],
        pre_hook = "{{ pre_macro() }}",
        post_hook = "{{ post_macro() }}"
        ) }}

with ice1 as(
    select * from {{ ref('ice_model1') }}
),

ice2 as(
    select * from {{ ref('ice_model2') }}
),

final as(
    select a.user_name, a.user_status from ice1 a join ice2 b on a.user_status = b.user_status
)

select * from final