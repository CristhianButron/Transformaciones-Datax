{#
  T9 — Diccionario de negocio (recodificación de nombres o códigos)
  Diccionario_de_Transformaciones.xlsx, hoja T9.

  Un valor se reemplaza por su equivalente de un catálogo de negocio
  (abreviatura expandida, código traducido, nombre comercial). Requiere un
  catálogo completo (seed), no un patrón inferido de 2-3 ejemplos.

  ⚠ El catálogo NO es universal entre cubos aunque vengan de la misma fuente
  (confirmado varias veces en el diccionario: NAL-P->NAL-V en unos cubos,
  NAL-P sin cambio en otros). Cada cubo declara su propio catalogo_ref.
#}

{#
  t9_join_catalogo: hace el LEFT JOIN contra un catálogo (seed) para poder
  recodificar un valor. El resultado se selecciona aparte, ej.:
      {{ t9_join_catalogo(ref('cat_compania_aps'), 'c', 'compania_raw', 'raw_code') }}
      ...
      select c.clean_code as compania, ...

  catalogo_relation: relación del catálogo, normalmente ref('nombre_seed').
  alias: alias SQL a usar para el catálogo en el join.
  columna_izquierda: columna/expresión del lado izquierdo (la tabla que se
      está recodificando) que se compara contra el catálogo.
  columna_catalogo_raw: columna del catálogo que contiene el valor "crudo"
      (el que aparece en la fuente), para hacer el match.
  tipo_join: 'left' (por defecto, no descarta filas sin match) o 'inner'.
#}
{% macro t9_join_catalogo(catalogo_relation, alias, columna_izquierda, columna_catalogo_raw, tipo_join='left') %}
{{ tipo_join }} join {{ catalogo_relation }} as {{ alias }}
    on {{ alias }}.{{ columna_catalogo_raw }} = {{ columna_izquierda }}
{%- endmacro %}
