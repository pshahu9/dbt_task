{% materialization iceberg, adapter='default' %}
    {% call statement('main') %}
        CREATE TABLE {{ this }} AS (
            {{ sql }}
        )
        EXTERNAL_VOLUME = 'S3_ICEBERG_STORE'
        CATALOG = 'SNOWFLAKE'
        BASE_LOCATION = ''
    {% endcall %}
    {{ return({'relations': [this]}) }}
{% endmaterialization %}
