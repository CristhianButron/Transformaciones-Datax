{{ config(materialized='view') }}

-- Cubo S_BOAPS_44_000620 (CSV 158). Transformaciones aplicadas: T1, T3, T8.
-- Toda la lógica vive en macros/transformaciones/ (t1_*, t3_*, t8_*) — este
-- modelo solo declara QUÉ tablas y QUÉ parámetros usa este cubo puntual.

{% set sufijos_tabla = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18'] %}
{% set fuentes = [] %}
{% for sufijo in sufijos_tabla %}
    {% do fuentes.append({'source_name': 'aps_raw', 'tabla': 'data_d_bo_000000447_' ~ sufijo}) %}
{% endfor %}

with union_18 as (

    -- T3: concatenación de las 18 tablas (Producción + Siniestros x 9 departamentos)
    {{ t3_union_fuentes(fuentes, ['titulo1', 'titulo3', 'modalidad', 'ramo', 'nv1', 'nv2', 'fecha', 'valor']) }}

)

select
    -- T1: titulo1 -> tipo (Produccion/Siniestros), por patrón, sin catálogo de negocio
    {{ t1_renombrar_patron('titulo1', [
        ('%Producci%', 'Produccion'),
        ('%Siniestro%', 'Siniestros')
    ]) }} as tipo,

    -- T8: normalización de texto — titulo1 -> Departamento, Title Case ("la PAZ" -> "La Paz")
    {{ t8_normalizar_texto('titulo3', 'titlecase') }} as departamento,

    modalidad,
    ramo,
    nv1 as tipo_entidad,

    -- T8: trim de espacios sobrantes en el código de compañía crudo
    {{ t8_normalizar_texto('nv2', 'trim') }} as compania_raw,

    fecha,
    valor as valor_usd -- ya viene limpio (T12 no aplica en este cubo)

from union_18
