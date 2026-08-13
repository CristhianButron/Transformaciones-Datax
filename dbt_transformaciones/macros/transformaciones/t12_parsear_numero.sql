{#
  T12 — Conversión de texto numérico con separador de miles a número (escala variable)
  Diccionario_de_Transformaciones.xlsx, hoja T12.

  ⚠ Confirmar el separador de miles de ESE reporte (no asumirlo) y la
  escala declarada (x1, x1.000, x1.000.000) con al menos un ejemplo real
  antes de aplicar a todo el archivo.
#}

{#
  t12_parsear_numero: limpia un número que llegó como texto y lo escala.

  columna: columna de texto a convertir.
  separador_miles: símbolo usado como separador de miles en ESTE reporte
      ('.' o ',', o '' si no trae separador de miles).
  separador_decimal: símbolo decimal, si es distinto de '.' (ej. ','
      en la convención española/boliviana). none = no tiene parte decimal
      o ya usa '.' (no se toca).
  escala: factor por el que multiplicar tras limpiar (1, 1000, 1000000, etc.)
      según la unidad declarada por el reporte ("En Miles de USD", etc.).
  notacion_contable: si true, reconoce paréntesis como negativo
      (ej. '(1.630)' -> -1630), patrón confirmado en S_BOSPVS66_000260.
#}
{% macro t12_parsear_numero(columna, separador_miles='.', separador_decimal=none, escala=1, notacion_contable=true) %}
    (
        {%- if notacion_contable %}
        case when trim({{ columna }}) like '(%' then -1 else 1 end *
        {%- endif %}
        nullif(
            {%- set limpio -%}
            replace(
                replace(
                    replace(trim({{ columna }}), '(', ''),
                    ')', ''
                ),
                '{{ separador_miles }}', ''
            )
            {%- endset -%}
            {%- if separador_decimal is not none -%}
            replace({{ limpio }}, '{{ separador_decimal }}', '.')
            {%- else -%}
            {{ limpio }}
            {%- endif %}
        , '')::numeric
        * {{ escala }}
    )
{%- endmacro %}
