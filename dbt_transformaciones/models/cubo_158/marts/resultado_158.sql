{{ config(materialized='table') }}

-- Cubo 158. Transformaciones aplicadas: T2, T4, T7, T9, T11, T16.
-- ⚠ El catálogo cat_compania_aps_158 fue confirmado para este cubo (y para
-- S_BOSPVS66_000260) — antes de reutilizarlo en otro cubo, verificar contra
-- ese cubo puntual (los catálogos NO son universales, ver diccionario T9).
-- ⚠ El catálogo NO tiene entrada para 4 compañías vistas en el CSV real de
-- referencia (158_datos_P.csv) que no aparecieron en los datos usados para
-- armar cat_compania_aps_158: 24S, LAT, PRO, ZUR. No se agregaron a ciegas
-- porque no tenemos su código crudo (nv2) confirmado — sin esa fila, esas
-- compañías van a caer sin "Compañia de Seguros" ni "Tipo Compañia de
-- Seguros" en el resultado. Completar cat_compania_aps_158.csv apenas se
-- tenga el nv2 real de esas 4.
--
-- Nombres de columnas y orden calcan el CSV de salida real (158_datos_P.csv)
-- en vez del nombre interno de trabajo (departamento/modalidad/anio/...),
-- para que el resultado de este pipeline sea comparable directamente.

with con_catalogo as (

    select
        d.tipo,
        d.departamento,
        d.modalidad,
        d.ramo,
        c.clean_code as compania,
        c.tipo_compania,
        d.anio,
        d.mes_num,
        d.fecha,
        d.valor_usd_mensual,

        -- T4: conversión de moneda, Bs = USD x 6.86 (vigente en 2025)
        {{ t4_convertir_moneda('d.valor_usd_mensual', 6.86, 'multiplicar') }} as valor_bs_mensual

    from {{ ref('int_cubo_158_desacumulado') }} d
    -- T9: catálogo de compañía (reemplaza el código crudo por el código limpio)
    -- T16: mismo catálogo también enriquece con tipo_compania (Generales y Fianzas / Personas)
    {{ t9_join_catalogo(ref('cat_compania_aps_158'), 'c', 'd.compania_raw', 'raw_code') }}

)

select
    anio as "Año",

    -- T7: número de mes -> nombre de mes en letras, en español
    {{ t7_mes_nombre('fecha') }} as "Mes",

    departamento as "Departamento",
    tipo_compania as "Tipo Compañia de Seguros",
    compania as "Compañia de Seguros",
    modalidad as "Tipo Seguro",
    ramo as "Ramo",

    -- T2 + T11: Producción y Siniestros, que llegaban en filas separadas
    -- (T3 las concatenó en stg_cubo_158), se pivotean a columnas paralelas
    -- de una misma fila. "Siniestros US$/Bs" solo existen al combinar ambos
    -- grupos de archivos — por eso también es T11.
    {{ t2_pivot_valor('tipo', 'Produccion', 'valor_usd_mensual') }} as "Producción US$",
    {{ t2_pivot_valor('tipo', 'Produccion', 'valor_bs_mensual') }} as "Producción Bs",
    {{ t2_pivot_valor('tipo', 'Siniestros', 'valor_usd_mensual') }} as "Siniestros US$",
    {{ t2_pivot_valor('tipo', 'Siniestros', 'valor_bs_mensual') }} as "Siniestros Bs"

from con_catalogo
group by departamento, tipo_compania, modalidad, ramo, compania, anio, mes_num, fecha
order by anio, mes_num, departamento, compania, ramo
