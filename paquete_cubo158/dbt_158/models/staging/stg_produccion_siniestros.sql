{{ config(materialized='view') }}

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
from ( {{ union_18_reportes() }} ) u
