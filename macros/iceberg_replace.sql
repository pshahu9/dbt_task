{% materialization iceberg_replace, adapter='default' %}
{% set external_volume =  config.require('external_volume',) %}
{% set catalog = config.require('catalog',)%}
{% set base_location = config.get('base_location', default='')%}
    {% call statement('main') %}
        {{ generate_iceberg_sql(this, sql, current_materialization, external_volume, catalog, base_location) }}
    {% endcall %}
    {{ return({'relations': [this]}) }}
{% endmaterialization %}

{% macro generate_iceberg_sql(model_name, sql, current_materialization, external_volume, catalog, base_location) %}
    {% if current_materialization == 'table' %}
        {% set iceberg_sql %}
            CREATE OR REPLACE ICEBERG TABLE {{ model_name }}
                EXTERNAL_VOLUME = '{{ external_volume }}'
                CATALOG = '{{ catalog }}'
                BASE_LOCATION = '{{ base_location }}'
            AS (
                {{ sql }}
            )      
        {% endset %}
    {% else %}
        {% set iceberg_sql %}
            ERROR: Cannot convert materialization to Iceberg table. Current materialization is not 'table'.
        {% endset %}
    {% endif %}
    
    {{ iceberg_sql }}
{% endmacro %}