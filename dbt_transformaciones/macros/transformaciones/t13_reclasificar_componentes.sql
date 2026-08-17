{#
  T13 — Reclasificación de varios "hechos" en una columna categórica (Componente)
  Diccionario_de_Transformaciones.xlsx, hoja T13.

  Varias filas de "hechos" de la fuente (Directo/Aceptado/Cedido) se
  reclasifican: se renombran, algunas invierten signo, y los totales
  derivados (que son solo la suma de los demás) se descartan. A diferencia
  de T2 (pivot), el resultado sigue en formato largo (una fila por
  componente), no se convierte en columnas.
#}

{#
  t13_reclasificar_componentes: arma el CASE de renombrado+signo y el
  filtro de exclusión para reclasificar componentes.

  hecho_col: columna con el nombre del "hecho" en la fuente (ej. 'hecho').
  componentes: dict {valor_origen: {'label': nuevo_nombre, 'signo': 1 o -1}}.
      Los valores del hecho_col que NO estén como llave en este dict se
      descartan (ej. la fila "Total", que es la suma de los demás).

  Devuelve un dict con:
      .hecho      -> expresión SQL para el nombre reclasificado del hecho.
      .filtro     -> expresión SQL (WHERE) que conserva solo los hechos
                     declarados en componentes.
      .signo(col) -> función que envuelve una columna de valor aplicando
                     el signo que corresponda a cada componente.
#}
{% macro t13_reclasificar_componentes(hecho_col, componentes) %}
    {%- set hecho_expr -%}
    case {{ hecho_col }}
        {%- for origen, cfg in componentes.items() %}
        when '{{ origen }}' then '{{ cfg.label }}'
        {%- endfor %}
    end
    {%- endset -%}
    {%- set filtro_expr -%}
    {{ hecho_col }} in ({% for origen in componentes.keys() %}'{{ origen }}'{{ ", " if not loop.last }}{% endfor %})
    {%- endset -%}
    {{ return({'hecho': hecho_expr, 'filtro': filtro_expr, 'componentes': componentes, 'hecho_col': hecho_col}) }}
{%- endmacro %}

{#
  t13_signo_componente: aplica el signo (1 o -1) que le corresponde a cada
  componente sobre una columna de valor, según el mismo dict de
  componentes usado en t13_reclasificar_componentes.
#}
{% macro t13_signo_componente(hecho_col, valor_col, componentes) %}
    (case {{ hecho_col }}
        {%- for origen, cfg in componentes.items() %}
        when '{{ origen }}' then {{ cfg.signo }}
        {%- endfor %}
        else 1
    end) * ({{ valor_col }})
{%- endmacro %}
