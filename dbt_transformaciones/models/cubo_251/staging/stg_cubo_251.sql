{{ config(materialized='view') }}

-- Cubo S_BOSPVS46_000251 (CSV 207) — Producción y Siniestros por Modalidad
-- y Ramo (nacional). Transformaciones aplicadas acá: T1, T7.
-- Fuente única (sin T3: un solo reporte, D_BO_000000447_25).

select
    u.id,

    -- T1: nv1 mezcla tipo + hecho en un solo campo ("Producción Directa
    -- Neta Anulaciones", "Siniestros por Reaseguro Aceptado", ...) — se
    -- separa por patrón, igual que titulo1 en el cubo 158.
    {{ t1_renombrar_patron('u.nv1', [
        ('Producci%', 'Produccion'),
        ('Siniestro%', 'Siniestros')
    ]) }} as tipo,

    -- T1: nv1 -> hecho (renombrado 1 a 1, sin catálogo de negocio — son
    -- los mismos 3 "hechos" del ejemplo T13 del diccionario, más 2
    -- agregados derivados por tipo que T13 descarta en el mart:
    -- "Neta Retenida" y "Total Suscrita" NO son hechos reales, son sumas
    -- de los otros 3 -- confirmado exacto contra datos reales:
    -- Producción Total Suscrita = Directo + Aceptado (8444000 = 7218000 + 1226000,
    -- fila id=... modalidad Seguros Generales, ramo Incendio, 2025-02-28);
    -- Siniestros Neto Retenido = Directo + Aceptado - Cedido (896000 = 2858000 + 793000 - 2755000,
    -- misma fila/fecha, exacto).
    {{ t1_renombrar_exacto('u.nv1', {
        'Producción Directa Neta Anulaciones': 'Directo',
        'Producción Aceptada en Reaseguro': 'Reaseguro Aceptado',
        'Producción Cedida a Reaseguro': 'Reaseguro Cedido',
        'Producción Neta Retenida': 'Neta Retenida',
        'Producción Total Suscrita': 'Total Suscrita',
        'Siniestros Directos': 'Directo',
        'Siniestros por Reaseguro Aceptado': 'Reaseguro Aceptado',
        'Siniestros Reembolsados por Reaseguro Cedido': 'Reaseguro Cedido',
        'Siniestros Neto Retenido': 'Neta Retenida',
        'Siniestros Totales': 'Total Suscrita'
    }) }} as hecho,

    -- T1: único cambio real de modalidad observado (mismo patrón que cubo 158)
    {{ t1_renombrar_exacto('u.modalidad', {'Servicios de Prepago': 'Servicios de Pre-Pago'}) }} as modalidad,

    u.ramo,
    u.fecha,

    -- T7: descomposición de fecha
    {{ t7_anio('u.fecha') }} as anio,
    {{ t7_mes_numero('u.fecha') }} as mes_num,

    u.valor::numeric as valor_usd -- ya viene en USD reales, sin escala (T12 no aplica: "En Miles de..." del título es inexacto, confirmado contra el CSV real)

from {{ source('aps_raw_251', 'data_d_bo_000000447_25') }} u
where u.metrica = 'moneda' and u.unidad_metrica = 'USD'
