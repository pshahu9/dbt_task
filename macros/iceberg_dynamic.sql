{% materialization iceberg_dynamic, adapter='default', supported_languages=['sql', 'python'] %}
{%- set identifier = model['alias'] -%}
{% set tags_config = config(tags) %}
{% set external_volume =  config.require('external_volume',) %}
{% set catalog = config.require('catalog',)%}
{% set base_location = config.get('base_location', default='')%}
{%- set full_refresh_mode = (should_full_refresh()) -%}
{%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
{%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, database=database, type='table') -%}    
{{- run_hooks(pre_hooks) -}}
{% if old_relation is none %}
    {% call statement('main') %}
        {{ create_iceberg_table(target_relation, sql, external_volume, catalog, base_location) }}
        {{ print(["Creating New model"]) }}
    {% endcall %}
{% elif full_refresh_mode %}
    {{ drop_relation_if_exists(old_relation) }}
    {{ print(["Full Refresh mode"]) }}
    {% call statement('main') %}
        {{ create_iceberg_table(target_relation, sql, external_volume, catalog, base_location) }}
    {% endcall %}
{% elif old_relation.is_table or old_relation.is_view %}
    {{ drop_relation_if_exists(old_relation) }}
    {{ print(["Dropping existing relation"]) }}
    {% call statement('main') %}
        {{ create_iceberg_table(target_relation, sql, external_volume, catalog, base_location) }}
    {% endcall %}
{% else %}     {#-- Implementation in progress for tmp_relation and incremental strategies--#}
    {% call statement('main') %}
        {{ create_iceberg_table(target_relation, sql, external_volume, catalog, base_location) }}
    {% endcall %}
{% endif %}
 
{{- run_hooks(post_hooks) -}}
    {{ print([sql]) }}
    {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}

{% macro create_iceberg_table(table_name, sql, external_volume, catalog, base_location) %}
    CREATE OR REPLACE ICEBERG TABLE {{ table_name }}
    EXTERNAL_VOLUME = '{{ external_volume }}'
    CATALOG = '{{ catalog }}'
    BASE_LOCATION = '{{ base_location }}'  
    AS (
        {{ sql }}
    )
{% endmacro %}