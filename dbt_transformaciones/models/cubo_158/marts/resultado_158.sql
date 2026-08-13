{{ config(materialized='table') }}

-- Cubo 158. Transformaciones aplicadas: T2, T4, T9, T11.
-- ⚠ El catálogo cat_compania_aps_158 fue confirmado para este cubo (y para
-- S_BOSPVS66_000260) — antes de reutilizarlo en otro cubo, verificar contra
-- ese cubo puntual (los catálogos NO son universales, ver diccionario T9).

with con_catalogo as (

    select
        d.tipo,
        d.departamento,
        d.modalidad,
        d.ramo,
        c.clean_code as compania,
        d.anio,
        d.mes_num,
        d.fecha,
        d.valor_usd_mensual,

        -- T4: conversión de moneda, Bs = USD x 6.86 (vigente en 2025)
        {{ t4_convertir_moneda('d.valor_usd_mensual', 6.86, 'multiplicar') }} as valor_bs_mensual

    from {{ ref('int_cubo_158_desacumulado') }} d
    -- T9: catálogo de compañía (reemplaza el código crudo por el código limpio)
    {{ t9_join_catalogo(ref('cat_compania_aps_158'), 'c', 'd.compania_raw', 'raw_code') }}

)

select
    departamento,
    modalidad,
    ramo,
    compania,
    anio,
    mes_num,
    fecha,

    -- T2 + T11: Producción y Siniestros, que llegaban en filas separadas
    -- (T3 las concatenó en stg_cubo_158), se pivotean a columnas paralelas
    -- de una misma fila. "siniestros_usd/bs" solo existen al combinar ambos
    -- grupos de archivos — por eso también es T11.
    {{ t2_pivot_valor('tipo', 'Produccion', 'valor_usd_mensual') }} as produccion_usd,
    {{ t2_pivot_valor('tipo', 'Produccion', 'valor_bs_mensual') }} as produccion_bs,
    {{ t2_pivot_valor('tipo', 'Siniestros', 'valor_usd_mensual') }} as siniestros_usd,
    {{ t2_pivot_valor('tipo', 'Siniestros', 'valor_bs_mensual') }} as siniestros_bs

from con_catalogo
group by departamento, modalidad, ramo, compania, anio, mes_num, fecha
order by departamento, compania, ramo, fecha
