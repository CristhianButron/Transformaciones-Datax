{#
  T7 — Descomposición de fecha
  Diccionario_de_Transformaciones.xlsx, hoja T7.

  Una columna de fecha se separa en Año / Mes / Día. Nombre de mes en letras,
  en español, sin depender de la configuración regional (locale) del motor
  de base de datos (por eso se usa un arreglo fijo en vez de to_char/TM).
#}

{% macro t7_meses_es() %}
    array['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']
{%- endmacro %}

{# t7_anio: extrae el año como entero. #}
{% macro t7_anio(fecha_col) %}
    extract(year from {{ fecha_col }})::int
{%- endmacro %}

{# t7_mes_numero: extrae el mes como entero (1-12). #}
{% macro t7_mes_numero(fecha_col) %}
    extract(month from {{ fecha_col }})::int
{%- endmacro %}

{# t7_mes_nombre: nombre del mes en letras, en español, Ene=1..Dic=12. #}
{% macro t7_mes_nombre(fecha_col) %}
    ({{ t7_meses_es() }})[extract(month from {{ fecha_col }})::int]
{%- endmacro %}

{# t7_dia: extrae el día del mes como entero (solo si el reporte es diario). #}
{% macro t7_dia(fecha_col) %}
    extract(day from {{ fecha_col }})::int
{%- endmacro %}
