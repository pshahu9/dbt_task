{% materialization table_materialization, adapter='default' %}
    {% call statement('main') %}
        create or replace table {{ this }}
        as ({{ sql }})
    {% endcall %}
    {{ return({'relations': [this]}) }}
{% endmaterialization %}