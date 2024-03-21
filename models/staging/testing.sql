{{
  config(
    stage_url = 's3://mosaic-data-catalog/dbt-stage/dummy_policy.csv'
  )
}}

select
 PARSE_JSON($1):CUSTOMER_ID::varchar as CUSTOMER_ID,
 PARSE_JSON($1):UMBRELLA_LIMIT::varchar as UMBRELLA_LIMIT
from @my_s3_stg