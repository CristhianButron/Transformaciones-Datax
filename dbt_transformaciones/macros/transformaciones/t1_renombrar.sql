{#
  T1 — Renombramiento (de columna o de valor)
  Diccionario_de_Transformaciones.xlsx, hoja T1.

  Renombrar una COLUMNA no necesita macro: se hace en el SELECT con
  "columna_origen as nombre_destino".

  Estos macros son para renombrar VALORES 1 a 1, sin catálogo de negocio
  (si el cambio de valor requiere decidir una equivalencia de negocio,
  no es T1, es T9 -> ver t9_diccionario_negocio.sql).
#}

{#
  t1_renombrar_exacto: reemplazo 1 a 1 por coincidencia exacta.
  mapping: dict {valor_origen: valor_destino}
  default: valor si no hay match (por defecto, deja el valor original)
#}
{% macro t1_renombrar_exacto(columna, mapping, default=none) %}
    case {{ columna }}
        {%- for origen, destino in mapping.items() %}
        when '{{ origen }}' then '{{ destino }}'
        {%- endfor %}
        else {{ default if default is not none else columna }}
    end
{%- endmacro %}

{#
  t1_renombrar_patron: reemplazo 1 a 1 por coincidencia de patrón (ilike).
  patrones: lista de [patron_ilike, valor_destino], evaluados en orden.
  default: valor si ningún patrón matchea (por defecto, deja el valor original)
#}
{% macro t1_renombrar_patron(columna, patrones, default=none) %}
    case
        {%- for patron, destino in patrones %}
        when {{ columna }} ilike '{{ patron }}' then '{{ destino }}'
        {%- endfor %}
        else {{ default if default is not none else columna }}
    end
{%- endmacro %}
