{#
  T8 — Normalización de texto (limpieza de forma, sin cambiar el significado)
  Diccionario_de_Transformaciones.xlsx, hoja T8.

  ⚠ La convención exacta se confirma por reporte, no se asume igual entre
  reportes del mismo proyecto (uno puede solo unificar mayúsculas, otro
  puede exigir además quitar tildes). Por eso el "modo" es un parámetro.

  El modo 'sin_tildes_oracion' requiere la extensión unaccent en Postgres:
      create extension if not exists unaccent;
#}

{#
  t8_normalizar_texto: normaliza un valor de texto según una convención.

  modo:
    'trim'               -> solo recorta espacios sobrantes al inicio/final.
    'titlecase'           -> trim + primera letra de cada palabra en mayúscula
                             (ej. 'la PAZ' -> 'La Paz').
    'mayusculas'          -> trim + todo en mayúsculas.
    'minusculas'          -> trim + todo en minúsculas.
    'sin_tildes_oracion'  -> trim + sin tildes + solo la primera letra del
                             texto en mayúscula, el resto en minúsculas
                             (caso ADUANA: capítulos NANDINA).
#}
{% macro t8_normalizar_texto(columna, modo='titlecase') %}
    {%- if modo == 'trim' -%}
    trim({{ columna }})
    {%- elif modo == 'titlecase' -%}
    initcap(trim({{ columna }}))
    {%- elif modo == 'mayusculas' -%}
    upper(trim({{ columna }}))
    {%- elif modo == 'minusculas' -%}
    lower(trim({{ columna }}))
    {%- elif modo == 'sin_tildes_oracion' -%}
    (upper(left(unaccent(trim({{ columna }})), 1)) || lower(substring(unaccent(trim({{ columna }})) from 2)))
    {%- else -%}
    {{ exceptions.raise_compiler_error("t8_normalizar_texto: modo desconocido: " ~ modo) }}
    {%- endif -%}
{%- endmacro %}
