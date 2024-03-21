{% materialization iceberg_incremental, adapter='default', supported_languages=['sql', 'python'] %}
{%- set identifier = model['alias'] -%}
{% set tags_config = config(tags) %}
{% set external_volume =  config.require('external_volume',) %}
{% set catalog = config.require('catalog',)%}
{% set base_location = config.get('base_location', default='')%}
{%- set full_refresh_mode = (should_full_refresh()) -%}
{%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
{%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, database=database, type='table') -%}    
{% set tmp_relation_type = dbt_snowflake_get_tmp_relation_type(incremental_strategy, unique_key, language) %}
{% set tmp_relation = make_temp_relation(this).incorporate(type=tmp_relation_type) %}
{% set existing_relation = load_relation(this) %}
{{- run_hooks(pre_hooks) -}}
{% if old_relation is none %}
    {% call statement('main') %}
        {{ create_iceberg_table(target_relation, sql, external_volume, catalog, base_location) }}
        {{ print(["New model"]) }}
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
    {% if tmp_relation_type == 'view' %}
        {%- call statement('create_tmp_relation') -%}
          {{ snowflake__create_view_as_with_temp_flag(tmp_relation, compiled_code, True) }}
        {%- endcall -%}
    {% else %}
        {%- call statement('create_tmp_relation', language=language) -%}
          {{ create_table_as(True, tmp_relation, compiled_code, language) }}
        {%- endcall -%}
    {% endif %}
    {% do adapter.expand_target_column_types(
           from_relation=tmp_relation,
           to_relation=target_relation) %}
    {#-- Process schema changes. Returns dict of changes if successful. Use source columns for upserting/merging --#}
    {% set dest_columns = process_schema_changes(on_schema_change, tmp_relation, existing_relation) %}
    {% if not dest_columns %}
      {% set dest_columns = adapter.get_columns_in_relation(existing_relation) %}
    {% endif %}
    {#-- Get the incremental_strategy, the macro to use for the strategy, and build the sql --#}
    {% set incremental_predicates = config.get('predicates', none) or config.get('incremental_predicates', none) %}
    {% set strategy_sql_macro_func = adapter.get_incremental_strategy_macro(context, incremental_strategy) %}
    {% set strategy_arg_dict = ({'target_relation': target_relation, 'temp_relation': tmp_relation, 'unique_key': unique_key, 'dest_columns': dest_columns, 'incremental_predicates': incremental_predicates }) %}

    {%- call statement('main') -%}
      {{ strategy_sql_macro_func(strategy_arg_dict) }}
    {%- endcall -%}
{% endif %}
  {% do drop_relation_if_exists(tmp_relation) %}

{{- run_hooks(post_hooks) -}}
    {{ print([sql]) }}
	{% set should_revoke = should_revoke(old_relation, full_refresh_mode=True) %}
    {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}
    {% do persist_docs(target_relation, model) %}
    {% do unset_query_tag(original_query_tag) %}
    {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}

{% macro dbt_snowflake_get_tmp_relation_type(strategy, unique_key, language) %}
{%- set tmp_relation_type = config.get('tmp_relation_type') -%}
  {% if language == "python" and tmp_relation_type is not none %}
    {% do exceptions.raise_compiler_error(
      "Python models currently only support 'table' for tmp_relation_type but "
       ~ tmp_relation_type ~ " was specified."
    ) %}
  {% endif %}

  {% if strategy == "delete+insert" and tmp_relation_type is not none and tmp_relation_type != "table" and unique_key is not none %}
    {% do exceptions.raise_compiler_error(
      "In order to maintain consistent results when `unique_key` is not none,
      the `delete+insert` strategy only supports `table` for `tmp_relation_type` but "
      ~ tmp_relation_type ~ " was specified."
      )
  %}
  {% endif %}

  {% if language != "sql" %}
    {{ return("table") }}
  {% elif tmp_relation_type == "table" %}
    {{ return("table") }}
  {% elif tmp_relation_type == "view" %}
    {{ return("view") }}
  {% elif strategy in ("default", "merge", "append") %}
    {{ return("view") }}
  {% elif strategy == "delete+insert" and unique_key is none %}
    {{ return("view") }}
  {% else %}
    {{ return("table") }}
  {% endif %}
{% endmacro %}
