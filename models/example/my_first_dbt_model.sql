

{{ config(
        materialized = 'iceberg_dynamic',
        external_volume='ICEBERG_EXT_VOL_2024',
        catalog='SNOWFLAKE',
        base_location=''
        )}}

with source_data as (

    select 1 as id
    union all
    select null as id

)

select *
from source_data

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
