{{ config(materialized='view') }}

-- Cubo S_BOAPS_44_000620 (CSV 158). Transformaciones aplicadas: T1, T3, T8, T9.
-- Toda la lógica vive en macros/transformaciones/ (t1_*, t3_*, t8_*, t9_*) —
-- este modelo solo declara QUÉ tablas y QUÉ parámetros usa este cubo puntual.
--
-- ⚠ cat_ramo_aps_158: catálogo parcial. Se armó comparando el CSV de salida
-- real (158_datos_P.csv) contra una corrida de este mismo pipeline, NO
-- contra los valores crudos verificados fila a fila (ver T9: "conseguir el
-- catálogo completo, no asumir un patrón"). Dos ramos observados en la
-- corrida real NO están mapeados a propósito por no tener evidencia
-- suficiente para decidir su equivalencia — quedan tal cual venían
-- (columna ramo del catálogo no los encuentra, join en null, coalesce a la
-- fila original): "Cumplimiento de Obligaciones y/o Derechos Contractuales"
-- y "Caución a Primer Requerimiento para el Pago Diferido de Tributos
-- Aduaneros de Importación". Verificarlos contra la fuente y completar.

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

    -- T1: modalidad -> Tipo Seguro, único cambio real: "Prepago" -> "Pre-Pago"
    {{ t1_renombrar_exacto('modalidad', {'Servicios de Prepago': 'Servicios de Pre-Pago'}) }} as modalidad,

    -- T9: ramo crudo -> nombre oficial del catálogo (ver advertencia arriba)
    coalesce(cr.clean_ramo, u.ramo) as ramo,

    nv1 as tipo_entidad,

    -- T8: trim de espacios sobrantes en el código de compañía crudo
    {{ t8_normalizar_texto('nv2', 'trim') }} as compania_raw,

    fecha,
    valor as valor_usd -- ya viene limpio (T12 no aplica en este cubo)

from union_18 u
{{ t9_join_catalogo(ref('cat_ramo_aps_158'), 'cr', 'u.ramo', 'raw_ramo') }}
