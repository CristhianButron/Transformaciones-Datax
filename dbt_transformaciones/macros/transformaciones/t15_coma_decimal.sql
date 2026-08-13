{#
  T15 — Conversión de coma decimal a punto decimal
  Diccionario_de_Transformaciones.xlsx, hoja T15.

  Un número pequeño llega como texto con COMA como separador decimal
  (convención española/boliviana), sin agrupación de miles. Se reemplaza
  la coma por punto, sin escala. Si el número SÍ agrupa miles cada 3
  dígitos, no es T15 — es T12 (ver t12_parsear_numero.sql).
#}

{% macro t15_coma_a_punto(columna) %}
    replace(trim({{ columna }}), ',', '.')::numeric
{%- endmacro %}
