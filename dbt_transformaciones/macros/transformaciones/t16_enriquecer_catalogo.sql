{#
  T16 — Enriquecimiento con código y/o jerarquía mediante catálogo de negocio
  Diccionario_de_Transformaciones.xlsx, hoja T16.

  Mismo mecanismo SQL que T9 (LEFT JOIN a un catálogo, ver
  t9_diccionario_negocio.sql), pero con otro propósito: T9 REEMPLAZA un
  valor por su equivalente; T16 AGREGA columnas nuevas (código, orden,
  jerarquía) que no existen en la fuente bajo ningún nombre, sin reemplazar
  nada. Se separa como macro propio para que el modelo del cubo quede
  documentado con el código T correcto del diccionario.
#}

{#
  t16_join_catalogo: idéntico a t9_join_catalogo — ver esa definición para
  los parámetros. Ejemplo de uso:
      {{ t16_join_catalogo(ref('cat_administracion_aduana'), 'adm', 'administracion_aduanera', 'nombre_administracion') }}
      ...
      select adm.orden_administracion, adm.departamento, ...
#}
{% macro t16_join_catalogo(catalogo_relation, alias, columna_izquierda, columna_catalogo_raw, tipo_join='left') %}
{{ t9_join_catalogo(catalogo_relation, alias, columna_izquierda, columna_catalogo_raw, tipo_join) }}
{%- endmacro %}
