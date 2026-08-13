{#
  T3 — Unión de tablas (merge y concatenación)
  Diccionario_de_Transformaciones.xlsx, hoja T3.

  Generaliza lo que antes era un macro por cubo (ej. union_18_reportes()):
  en vez de escribir un SELECT por tabla a mano, se itera sobre una lista
  que viene del config del cubo (a futuro, del Plan Maestro de Cubos).

  El "merge" (unión por llave común) no necesita macro propio: es un JOIN
  normal en el modelo, usando ref()/source() como siempre.
#}

{#
  t3_union_fuentes: concatena N tablas fuente que comparten la misma
  estructura de columnas (union all).

  fuentes: lista de dicts, cada uno con:
      - source_name: nombre del source (sources.yml)
      - tabla: identifier de la tabla dentro de ese source
      - extra (opcional): dict {alias_columna: expresion_sql_literal} para
        inyectar columnas que no vienen en la tabla pero se infieren de cuál
        tabla es (ej. el departamento, cuando viene del nombre del reporte
        y no de una columna real).
  columnas: lista de columnas a seleccionar de cada tabla, en el mismo orden
      en todas (deben existir con ese nombre en cada tabla fuente).
#}
{% macro t3_union_fuentes(fuentes, columnas) %}
    {%- for fuente in fuentes %}
        select
            {%- for col in columnas %}
            {{ col }}{{ "," if not loop.last or fuente.extra }}
            {%- endfor %}
            {%- if fuente.extra %}
            {%- for alias, expr in fuente.extra.items() %}
            {{ expr }} as {{ alias }}{{ "," if not loop.last }}
            {%- endfor %}
            {%- endif %}
        from {{ source(fuente.source_name, fuente.tabla) }}
        {% if not loop.last %}union all{% endif %}
    {%- endfor %}
{%- endmacro %}
