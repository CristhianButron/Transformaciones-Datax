
  create view "copia"."public"."stg_produccion_siniestros__dbt_tmp"
    
    
  as (
    

-- T3: concatenacion de las 18 tablas (via el macro)
-- T1: titulo1 -> Tipo (Produccion/Siniestros) ; titulo3 -> Departamento
-- T8: normalizacion de texto (Departamento en Title Case, ej. "la PAZ" -> "La Paz")
-- T7: fecha ya viene como DATE, solo se descompone en Anio/Mes en el mart final
-- T9: normalizacion del codigo de compania (nv2) -- el catalogo completo se aplica en el mart

select
    case
        when titulo1 ilike '%Producci%' then 'Produccion'
        when titulo1 ilike '%Siniestro%' then 'Siniestros'
        else titulo1
    end                                            as tipo,             -- T1 (derivado de titulo1)
    initcap(lower(trim(titulo3)))                   as departamento,     -- T1 + T8
    modalidad,
    ramo,
    nv1                                              as tipo_entidad,
    trim(nv2)                                        as compania_raw,    -- T8 (trim)
    fecha,
    valor                                            as valor_usd        -- ya viene limpio (T12 resuelto en la ingesta)
from ( 

    

    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_01"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_02"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_03"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_04"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_05"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_06"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_07"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_08"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_09"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_10"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_11"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_12"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_13"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_14"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_15"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_16"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_17"
         union all 
    
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from "copia"."public"."data_d_bo_000000447_18"
        
    

 ) u
  );