MODEL (
  name sqlmesh_cubo158.resultado_158,
  kind FULL,
  audits (
    not_null(columns := ("Departamento", "Compañia de Seguros", "Año", "Mes")),
  ),
);

-- T2, T4, T7, T9, T11, T16. Réplica funcional de
-- dbt_transformaciones/models/cubo_158/marts/resultado_158.sql (rama
-- ejemplo1 [DBT-1]) — mismas columnas, mismo orden final, para que el
-- resultado sea comparable fila a fila con dbt.

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

        -- T4: conversión de moneda, Bs = USD x 6.86
        round(d.valor_usd_mensual * 6.86, 2) as valor_bs_mensual

    from sqlmesh_cubo158.int_cubo_158_desacumulado d
    -- T9 + T16: catálogo de compañía (reemplaza el código y agrega tipo_compania)
    left join sqlmesh_cubo158.cat_compania_aps_158 c on c.raw_code = d.compania_raw

)

select
    anio as "Año",

    -- T7: número de mes -> nombre en español
    (array['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto',
           'Septiembre','Octubre','Noviembre','Diciembre'])[extract(month from fecha)::int] as "Mes",

    departamento as "Departamento",
    tipo_compania as "Tipo Compañia de Seguros",
    compania as "Compañia de Seguros",
    modalidad as "Tipo Seguro",
    ramo as "Ramo",

    -- T2 + T11: Producción y Siniestros pivoteados a columnas paralelas
    max(case when tipo = 'Produccion' then valor_usd_mensual end) as "Producción US$",
    max(case when tipo = 'Produccion' then valor_bs_mensual end) as "Producción Bs",
    max(case when tipo = 'Siniestros' then valor_usd_mensual end) as "Siniestros US$",
    max(case when tipo = 'Siniestros' then valor_bs_mensual end) as "Siniestros Bs"

from con_catalogo
group by departamento, tipo_compania, modalidad, ramo, compania, anio, mes_num, fecha
order by
    anio,
    mes_num,
    tipo_compania,
    compania,
    modalidad,
    ramo,
    case departamento
        when 'La Paz' then 1
        when 'Cochabamba' then 2
        when 'Santa Cruz' then 3
        when 'Oruro' then 4
        when 'Potosí' then 5
        when 'Pando' then 6
        when 'Beni' then 7
        when 'Chuquisaca' then 8
        when 'Tarija' then 9
        else 10
    end
