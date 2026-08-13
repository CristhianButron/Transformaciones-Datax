
  
    

  create  table "copia"."public"."resultado_158__dbt_tmp"
  
  
    as
  
  (
    

-- T9: catalogo de compania (reutiliza el patron ya conocido del proyecto -- VERIFICAR,
--     ver nota en el chat: los catalogos no son universales entre cubos)
-- T4: conversion de moneda, Bs = USD x 6.86
-- T11: Produccion y Siniestros se combinan en la misma fila (columnas separadas)
--      -- esto es lo que "no existe en ningun archivo por separado"

with con_catalogo as (

    select
        d.tipo,
        d.departamento,
        d.modalidad,
        d.ramo,
        c.clean_code            as compania,
        d.anio,
        d.mes_num,
        d.fecha,
        d.valor_usd_mensual,
        round(d.valor_usd_mensual * 6.86, 2) as valor_bs_mensual
    from "copia"."public"."int_desacumulado" d
    left join "copia"."public"."cat_compania" c on c.raw_code = d.compania_raw

)

select
    departamento,
    modalidad,
    ramo,
    compania,
    anio,
    mes_num,
    fecha,

    max(case when tipo = 'Produccion' then valor_usd_mensual end) as produccion_usd,
    max(case when tipo = 'Produccion' then valor_bs_mensual  end) as produccion_bs,
    max(case when tipo = 'Siniestros' then valor_usd_mensual end) as siniestros_usd,
    max(case when tipo = 'Siniestros' then valor_bs_mensual  end) as siniestros_bs

from con_catalogo
group by departamento, modalidad, ramo, compania, anio, mes_num, fecha
order by departamento, compania, ramo, fecha
  );
  