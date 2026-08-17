{#
  T5 — Cálculo de un nuevo dato mediante operaciones entre datos existentes
  Diccionario_de_Transformaciones.xlsx, hoja T5.

  No es conversión de moneda (eso es T4). Cubre operaciones aritméticas
  simples entre columnas existentes, o desplazamientos fijos de fecha.
  Si el cálculo no encaja en estos dos casos genéricos, se escribe la
  expresión puntual directamente en el modelo del cubo (T5 es, por
  definición, específico de cada reporte).
#}

{#
  t5_promedio: promedio simple de dos columnas; si falta una, usa la única
  disponible en vez de promediar contra NULL (caso confirmado FINRURAL:
  Tasa Menor% + Tasa Mayor% -> Tasa Prom.%).
#}
{% macro t5_promedio(columna_a, columna_b, decimales=2) %}
    case
        when {{ columna_a }} is not null and {{ columna_b }} is not null
            then round((({{ columna_a }}) + ({{ columna_b }})) / 2.0, {{ decimales }})
        when {{ columna_a }} is not null then {{ columna_a }}
        else {{ columna_b }}
    end
{%- endmacro %}

{#
  t5_offset_fecha: suma/resta N días fijos a una fecha existente (regla de
  negocio fija, no un error de datos). Confirmar con 5+ ejemplos reales
  antes de aplicar (caso BCB: fecha de liquidación = fecha del boletín + 3).
  dias puede ser negativo para restar.
#}
{% macro t5_offset_fecha(fecha_col, dias) %}
    ({{ fecha_col }} + interval '{{ dias }} day')::date
{%- endmacro %}
