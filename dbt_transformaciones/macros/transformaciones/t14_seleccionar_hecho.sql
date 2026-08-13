{#
  T14 — Selección de un "hecho" específico entre varios calculados, descartando el resto
  Diccionario_de_Transformaciones.xlsx, hoja T14.

  De varios "hechos" que trae la fuente para la misma entidad (Directo,
  Aceptado, Cedido, Neto Retenido...), el resultado se queda con UNO solo y
  descarta el resto — sin crear columna categórica (a diferencia de T13).
  Confirmar con varios ejemplos reales cuál hecho es el que realmente se usa.
#}

{#
  t14_filtro_hecho: condición WHERE que conserva solo el hecho deseado.
  hecho_col: columna con el nombre del "hecho" en la fuente.
  hecho_deseado: el único valor de hecho_col que debe sobrevivir.
#}
{% macro t14_filtro_hecho(hecho_col, hecho_deseado) %}
{{ hecho_col }} = '{{ hecho_deseado }}'
{%- endmacro %}
