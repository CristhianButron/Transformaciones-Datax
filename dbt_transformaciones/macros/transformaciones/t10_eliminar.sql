{#
  T10 — Eliminación de columnas o de registros completos
  Diccionario_de_Transformaciones.xlsx, hoja T10.

  Eliminar COLUMNAS no necesita macro: simplemente no se seleccionan en el
  SELECT del modelo (metadatos técnicos, IDs, columnas sin valor analítico).

  Eliminar FILAS (subtotales, pruebas, duplicados, vacías) se resuelve con
  un WHERE — este macro arma esa condición de forma reutilizable.
#}

{#
  t10_filtro_filas_validas: combina varias condiciones de exclusión en un
  único WHERE. condiciones es una lista de expresiones booleanas SQL que
  deben cumplirse TODAS para que la fila se conserve, ej.:
      {{ t10_filtro_filas_validas([
          "departamento not ilike 'TOTAL%'",
          "valor is not null",
      ]) }}
#}
{% macro t10_filtro_filas_validas(condiciones) %}
({{ condiciones | join(') and (') }})
{%- endmacro %}
