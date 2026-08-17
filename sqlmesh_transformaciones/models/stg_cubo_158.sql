MODEL (
  name sqlmesh_cubo158.stg_cubo_158,
  kind VIEW,
);

-- Réplica funcional de dbt_transformaciones/models/cubo_158/staging/stg_cubo_158.sql
-- (rama ejemplo1 [DBT-1]). Mismas transformaciones (T1, T3, T8, T9), misma
-- fuente real (18 tablas del cubo S_BOAPS_44_000620 / CSV 158).
--
-- Diferencia principal frente a dbt: acá no existe un macro genérico
-- t3_union_fuentes reutilizable entre cubos (SQLMesh sí soporta macros
-- Python/SQL propios para este patrón — ver el informe Hito 2, sección
-- SQLMesh — pero para esta prueba puntual se escribió explícito, igual
-- que la primera versión hardcodeada de dbt antes de generalizarla).

with union_18 as (

    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_01
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_02
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_03
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_04
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_05
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_06
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_07
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_08
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_09
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_10
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_11
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_12
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_13
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_14
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_15
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_16
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_17
    union all
    select titulo1, titulo3, modalidad, ramo, nv1, nv2, fecha, valor from public.data_d_bo_000000447_18

)

select
    -- T1: titulo1 -> tipo (Produccion/Siniestros), por patrón
    case
        when u.titulo1 ilike '%Producci%' then 'Produccion'
        when u.titulo1 ilike '%Siniestro%' then 'Siniestros'
        else u.titulo1
    end as tipo,

    -- T8: normalización de texto, Title Case
    initcap(trim(u.titulo3)) as departamento,

    -- T1: único cambio real de modalidad observado en el CSV real
    case u.modalidad
        when 'Servicios de Prepago' then 'Servicios de Pre-Pago'
        else u.modalidad
    end as modalidad,

    -- T9: catálogo de ramo (ver advertencia de cobertura parcial en el README)
    coalesce(cr.clean_ramo, u.ramo) as ramo,

    u.nv1 as tipo_entidad,

    -- T8: trim de espacios sobrantes
    trim(u.nv2) as compania_raw,

    u.fecha,
    u.valor as valor_usd

from union_18 u
left join sqlmesh_cubo158.cat_ramo_aps_158 cr on cr.raw_ramo = u.ramo
