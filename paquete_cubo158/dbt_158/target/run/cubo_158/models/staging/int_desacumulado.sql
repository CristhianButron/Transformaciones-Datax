
  create view "copia"."public"."int_desacumulado__dbt_tmp"
    
    
  as (
    

-- T6: Desacumulacion. La fuente reporta el acumulado del anio calendario hasta la fecha
-- (se resetea cada Enero). El valor real del mes = acumulado actual - acumulado del mes
-- anterior DENTRO DEL MISMO ANIO. Enero = el acumulado tal cual (no hay mes previo que restar).

with base as (

    select
        tipo,
        departamento,
        modalidad,
        ramo,
        tipo_entidad,
        compania_raw,
        fecha,
        extract(year from fecha)::int  as anio,
        valor_usd                      as acumulado_usd,
        lag(valor_usd) over (
            partition by tipo, departamento, modalidad, ramo, compania_raw, extract(year from fecha)
            order by fecha
        ) as acumulado_mes_anterior

    from "copia"."public"."stg_produccion_siniestros"

)

select
    tipo,
    departamento,
    modalidad,
    ramo,
    tipo_entidad,
    compania_raw,
    fecha,
    anio,
    extract(month from fecha)::int as mes_num,
    case
        when acumulado_mes_anterior is null then acumulado_usd                       -- enero (o primer mes con dato del anio)
        else acumulado_usd - acumulado_mes_anterior
    end as valor_usd_mensual

from base
  );