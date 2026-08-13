{#
  T4 — Conversión de moneda
  Diccionario_de_Transformaciones.xlsx, hoja T4.

  ⚠ Antes de usar: confirmar con 3+ ejemplos reales la moneda de origen,
  la dirección (multiplicar/dividir) y si la tasa cambia según la fecha
  (ver T4 en el diccionario para el caso ADUANA: 6.11 en 2000, 6.86 desde 2012).
#}

{#
  t4_convertir_moneda: convierte un monto multiplicando o dividiendo por una
  tasa de cambio.

  monto_col: columna o expresión con el monto de origen.
  tasa: número fijo (ej. 6.86) o una expresión/columna SQL si la tasa varía
        por fila (ej. proveniente de un join a una tabla de tasas históricas
        como la de ADUANA, donde 6.11..8.05 según el año). El macro no le
        importa si es literal o columna, solo lo interpola en la fórmula.
  direccion: 'multiplicar' (fuente en USD, destino en Bs) o
             'dividir' (fuente en Bs, destino en USD).
  decimales: redondeo del resultado (2 por defecto).
#}
{% macro t4_convertir_moneda(monto_col, tasa, direccion, decimales=2) %}
    {%- if direccion == 'multiplicar' -%}
    round(({{ monto_col }}) * ({{ tasa }}), {{ decimales }})
    {%- elif direccion == 'dividir' -%}
    round(({{ monto_col }}) / ({{ tasa }}), {{ decimales }})
    {%- else -%}
    {{ exceptions.raise_compiler_error("t4_convertir_moneda: direccion debe ser 'multiplicar' o 'dividir', recibido: " ~ direccion) }}
    {%- endif -%}
{%- endmacro %}
