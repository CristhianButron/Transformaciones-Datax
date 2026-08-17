{{ config(materialized='view') }}

-- Cubo 158. Transformaciones aplicadas: T6, T7.
-- El ciclo de acumulación se reinicia cada año calendario (Enero = igual
-- al acumulado); ver macro t6_desacumular. La partición incluye el año
-- para que el reinicio de Enero no reste contra Diciembre del año anterior.

select
    tipo,
    departamento,
    modalidad,
    ramo,
    tipo_entidad,
    compania_raw,
    fecha,

    -- T7: descomposición de fecha
    {{ t7_anio('fecha') }} as anio,
    {{ t7_mes_numero('fecha') }} as mes_num,

    -- T6: desacumulación (acumulado actual - acumulado del mes anterior, dentro del mismo año)
    {{ t6_desacumular(
        valor_col='valor_usd',
        partition_by=['tipo', 'departamento', 'modalidad', 'ramo', 'compania_raw', t7_anio('fecha')],
        order_by='fecha'
    ) }} as valor_usd_mensual

from {{ ref('stg_cubo_158') }}
