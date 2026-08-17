{#
  T6 — Desacumulación (de valor acumulado a valor por periodo)
  Diccionario_de_Transformaciones.xlsx, hoja T6.

  valor_del_periodo = acumulado_actual - acumulado_anterior
  primer periodo del ciclo (ej. Enero) = igual al acumulado (no hay anterior).

  ⚠ No todo lo que se llama "acumulado" se desacumula — confirmar con 3+
  periodos reales que el dato solo crece o se mantiene dentro del ciclo
  antes de aplicar esto. Si la columna destino conserva "Acum" en el nombre,
  probablemente NO lleva T6 (caso ADUANA: "Monto Bs Acum" se deja tal cual).
#}

{#
  t6_desacumular: resta el acumulado del periodo anterior DENTRO de la
  misma partición (normalmente entidad + año, para que el ciclo se
  reinicie cada año).

  valor_col: columna con el valor acumulado.
  partition_by: lista de columnas/expresiones que definen "la misma serie,
      el mismo ciclo" (ej. ['departamento', 'compania', 'extract(year from fecha)']).
  order_by: columna/expresión que ordena los periodos dentro del ciclo (ej. 'fecha').
#}
{% macro t6_desacumular(valor_col, partition_by, order_by) %}
    coalesce(
        {{ valor_col }} - lag({{ valor_col }}) over (
            partition by {{ partition_by | join(', ') }}
            order by {{ order_by }}
        ),
        {{ valor_col }}
    )
{%- endmacro %}
