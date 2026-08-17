{#
  T2 — Reestructuración de columnas (pivot)
  Diccionario_de_Transformaciones.xlsx, hoja T2.

  La fuente trae los datos en formato largo (columna "categoria" + columna
  "valor"); el resultado convierte cada categoria en su propia columna.
  Se usa dentro de un SELECT con GROUP BY sobre la llave (entidad+fecha, etc).
  Si falta una categoria para una llave, la columna queda NULL (no se inventa).

  Nota: esta misma forma (max(case when categoria = x then valor end)) es la
  que resuelve T11 (columna nueva que solo aparece al cruzar 2 archivos) y
  T2 (pivot clasico) al mismo tiempo — la diferencia entre T2/T11 es de dónde
  viene la fila, no la forma del SQL.
#}

{#
  t2_pivot_valor: agrega una columna que "recoge" el valor de una categoria.
  categoria_col: columna que indica el tipo de dato (ej. 'metrica', 'tipo', 'nv2')
  categoria_valor: el valor puntual de esa categoria a pivotear (ej. 'Interés Mínimo')
  valor_col: columna con el valor a agregar (ej. 'valor')
  agregacion: función de agregación a usar (max por defecto; sirve sum, min, etc.)
#}
{% macro t2_pivot_valor(categoria_col, categoria_valor, valor_col, agregacion='max') %}
    {{ agregacion }}(case when {{ categoria_col }} = '{{ categoria_valor }}' then {{ valor_col }} end)
{%- endmacro %}
