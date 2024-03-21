{{ config(
        materialized = 'iceberg_dynamic',
        external_volume='ICEBERG_EXT_VOL_2024',
        catalog='SNOWFLAKE',
        base_location='') }}
        
{{ select_macro() }}

