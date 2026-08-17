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

{#
  t9_join_catalogo_compuesto: igual que t9_join_catalogo, pero para
  catálogos cuya llave no es una sola columna (ej. un mismo valor de ramo
  se traduce distinto según la modalidad — caso confirmado con datos
  reales en S_BOSPVS46_000251: "Salud o Enfermedad" -> "Salud o Enfermedad"
  bajo Seguros Generales, pero -> "Salud o enfermedad" bajo Seguros de
  Personas/Servicios de Prepago).

  llaves: lista de pares [columna_izquierda, columna_catalogo] a unir con AND,
      ej. [['d.modalidad', 'raw_modalidad'], ['d.ramo', 'raw_ramo']].
#}
{% macro t9_join_catalogo_compuesto(catalogo_relation, alias, llaves, tipo_join='left') %}
{{ tipo_join }} join {{ catalogo_relation }} as {{ alias }}
    on {% for izq, cat in llaves %}{{ alias }}.{{ cat }} = {{ izq }}{{ ' and ' if not loop.last }}{% endfor %}
{%- endmacro %}
