{{ config(materialized='table') }}

-- Cubo 251 (S_BOSPVS46_000251). Transformaciones aplicadas: T4, T7, T9, T13.
-- ⚠ cat_ramo_aps_251 es un catálogo de llave COMPUESTA (modalidad + ramo):
-- un mismo ramo crudo se traduce distinto según la modalidad — confirmado
-- con datos reales (ej. "Salud o Enfermedad" -> "Salud o Enfermedad" bajo
-- Seguros Generales, pero -> "Salud o enfermedad" bajo Seguros de Personas
-- y Servicios de Prepago). No reutilizar cat_ramo_aps_158 (llave simple)
-- para este cubo aunque comparten casi todos los valores — confirmado que
-- al menos "Vitalicios" -> "Seguros Vitalicios" acá, distinto de 158.
-- Queda 1 ramo sin mapear a propósito por evidencia insuficiente (solo 4
-- filas, 50/50 entre dos posibles destinos): "Caución a Primer
-- Requerimiento para el Pago Diferido de Tributos Aduaneros de Importación".
--
-- ⚠ cat_tasa_cambio_251 se derivó completo de 207_datos_P.csv (Bs/USD por
-- mes, 2004-03 a 2026-05, 266 filas, consistencia 100% dentro de cada mes)
-- — no de un tipo de cambio oficial documentado aparte. Válido para
-- reproducir el histórico ya observado; si aparecen meses nuevos fuera de
-- ese rango hay que agregarlos.

with con_catalogos as (

    select
        d.tipo,
        d.hecho,
        d.modalidad,
        coalesce(cr.clean_ramo, d.ramo) as ramo,
        d.anio,
        d.mes_num,
        d.fecha,
        d.valor_usd,

        -- T4: tasa variable por mes (no es un número fijo como en el 158)
        {{ t4_convertir_moneda('d.valor_usd', 'tc.tasa::numeric', 'multiplicar') }} as valor_bs

    from {{ ref('stg_cubo_251') }} d
    -- T9: catálogo de ramo con llave compuesta modalidad + ramo
    {{ t9_join_catalogo_compuesto(ref('cat_ramo_aps_251'), 'cr', [['d.modalidad', 'modalidad'], ['d.ramo', 'raw_ramo']]) }}
    left join {{ ref('cat_tasa_cambio_251') }} tc on tc.anio = d.anio and tc.mes_num = d.mes_num

),

-- T13: Directo/Reaseguro Aceptado/Reaseguro Cedido se reclasifican con
-- signo (Cedido en negativo); "Neta Retenida" y "Total Suscrita" son
-- agregados derivados de los otros 3 y se descartan (confirmado exacto
-- contra datos reales, ver comentario en stg_cubo_251.sql).
{% set t13cfg = t13_reclasificar_componentes('hecho', {
    'Directo': {'label': 'Directo', 'signo': 1},
    'Reaseguro Aceptado': {'label': 'Reaseguro Aceptado', 'signo': 1},
    'Reaseguro Cedido': {'label': 'Reaseguro Cedido', 'signo': -1}
}) %}

reclasificado as (

    select
        anio,
        mes_num,
        fecha,
        modalidad,
        ramo,
        tipo,
        {{ t13cfg.hecho }} as componente,
        {{ t13_signo_componente('hecho', 'valor_usd', t13cfg.componentes) }} as valor_usd_signed,
        {{ t13_signo_componente('hecho', 'valor_bs', t13cfg.componentes) }} as valor_bs_signed

    from con_catalogos
    where {{ t13cfg.filtro }}

)

select
    anio as "Año",

    -- T7: número de mes -> nombre en español
    {{ t7_mes_nombre('fecha') }} as "Mes",

    modalidad as "Tipo de Seguro",
    ramo as "Ramo",
    componente as "Componente",

    max(case when tipo = 'Produccion' then valor_bs_signed end) as "Producción Bs",
    max(case when tipo = 'Produccion' then valor_usd_signed end) as "Producción US$",
    max(case when tipo = 'Siniestros' then valor_bs_signed end) as "Siniestros Bs",
    max(case when tipo = 'Siniestros' then valor_usd_signed end) as "Siniestros US$"

from reclasificado
group by anio, mes_num, fecha, modalidad, ramo, componente
order by anio, mes_num, modalidad, ramo, componente
