{{
  config(
    materialized = 'incremental',
    unique_key = 'alert_id'
  )
}}

with dbt_runs as (

    select * from {{ elementary.get_source_path('dbt_run_results') }}

),

alerts_model_runs as (

    {%- if var('alert_dbt_model_fail') %}
     select
         model_execution_id as alert_id,
         generated_at as detected_at,
         '{{ elementary.target_database() }}' as database_name,
         '{{ target.schema }}' as schema_name,
         name as table_name,
         {{ elementary.null_to_string() }} as column_name,
         'dbt_model_failed' as alert_type,
         status as sub_type,
         {{ elementary.dbt_model_run_result_description() }} as alert_description
    from dbt_runs
    where resource_type = 'model'
        {%- if var('alert_dbt_model_skip') %}
        and status in ('error','skipped')
        {%- else %}
        and status = 'error'
        {%- endif %}
    {%- else %}
        {{ elementary.empty_alerts_cte() }}
    {%- endif %}

)

select * from alerts_model_runs