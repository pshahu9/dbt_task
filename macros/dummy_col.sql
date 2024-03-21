{% materialization dummy_col, adapter='default' %}

{%- set target_relation = this -%}
{%- set temp_relation = make_temp_relation(target_relation) -%}

{% set existing = load_cached_relation(target_relation) -%}
{%- if existing is none or should_full_refresh() -%}
    {%- set build_sql = get_dummy_col_sql_initial(temp_relation, target_relation, sql) -%}
{%- else -%}
    {%- set build_sql = get_dummy_col_sql(temp_relation, target_relation, sql) -%}
{%- endif -%}

{{- run_hooks(pre_hooks) -}}

{% call statement("main") %}
    {{ build_sql }}
{% endcall %}

{{- run_hooks(post_hooks) -}}

{{- return({'relations': [target_relation]}) -}}

{% endmaterialization %}

{% macro get_dummy_col_sql_initial(temp_relation, target_relation, sql) %}
    {{- get_create_table_as_sql(True, temp_relation, sql) -}}

    {%- set extra_col_sql -%}
        select
            *,
            'dummy_value' as dummy_column,
            'dummy_one' as dummy_column_one,
            'dummy_two' as dummy_column_two
        from {{ temp_relation }}
    {%- endset -%}

    {{- get_create_table_as_sql(False, target_relation, extra_col_sql) -}}
{% endmacro %}

{% macro get_dummy_col_sql(temp_relation, target_relation, sql) %}
    {{- get_create_table_as_sql(True, temp_relation, sql) -}}

    {%- set target_columns = adapter.get_columns_in_relation(target_table) -%}
    {%- set quoted_csv_columns = get_quoted_csv(target_columns | map(attribute="name")) -%}

    insert into {{ target_relation }}({{ quoted_csv_columns }})
    select
        *,
        'dummy_value' as dummy_column,
        'dummy_three' as dummy_three
    from {{ temp_relation }}
{% endmacro %}