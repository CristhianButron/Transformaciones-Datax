{#
  union_18_reportes()
  Arma un UNION ALL de las 18 tablas fuente del cubo S_BOAPS_44_000620
  (T3: concatenacion). Como las 18 tablas tienen exactamente la misma
  estructura, no hace falta escribir el SELECT 18 veces a mano: se
  itera sobre la lista y dbt arma el SQL solo.

  Esta es la misma logica que habria que usar para "miles de cubos":
  en vez de un modelo por tabla, un macro parametrizado por una lista
  (que a futuro puede venir de la Matriz de Clasificacion del Diccionario).
#}

{% macro union_18_reportes() %}

    {% set tablas = [
        'data_d_bo_000000447_01', 'data_d_bo_000000447_02', 'data_d_bo_000000447_03',
        'data_d_bo_000000447_04', 'data_d_bo_000000447_05', 'data_d_bo_000000447_06',
        'data_d_bo_000000447_07', 'data_d_bo_000000447_08', 'data_d_bo_000000447_09',
        'data_d_bo_000000447_10', 'data_d_bo_000000447_11', 'data_d_bo_000000447_12',
        'data_d_bo_000000447_13', 'data_d_bo_000000447_14', 'data_d_bo_000000447_15',
        'data_d_bo_000000447_16', 'data_d_bo_000000447_17', 'data_d_bo_000000447_18'
    ] %}

    {% for tabla in tablas %}
        select
            titulo1,
            titulo3,
            modalidad,
            ramo,
            nv1,
            nv2,
            fecha,
            valor
        from {{ source('aps_raw', tabla) }}
        {% if not loop.last %} union all {% endif %}
    {% endfor %}

{% endmacro %}
