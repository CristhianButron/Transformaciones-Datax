MODEL (
  name sqlmesh_cubo158.int_cubo_158_desacumulado,
  kind VIEW,
);

-- T7 + T6. Réplica funcional de
-- dbt_transformaciones/models/cubo_158/staging/int_cubo_158_desacumulado.sql

select
    tipo,
    departamento,
    modalidad,
    ramo,
    tipo_entidad,
    compania_raw,
    fecha,

    extract(year from fecha)::int as anio,
    extract(month from fecha)::int as mes_num,

    -- T6: desacumulación (acumulado actual - acumulado del mes anterior,
    -- dentro del mismo año; primer mes del ciclo = igual al acumulado)
    coalesce(
        valor_usd - lag(valor_usd) over (
            partition by tipo, departamento, modalidad, ramo, compania_raw, extract(year from fecha)
            order by fecha
        ),
        valor_usd
    ) as valor_usd_mensual

from sqlmesh_cubo158.stg_cubo_158
