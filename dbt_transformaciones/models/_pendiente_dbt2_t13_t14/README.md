# [DBT-2] — pendiente de datos reales (T13/T14)

Esta rama es la **prueba DBT-2** del informe Hito 2: validar T13
(reclasificación de componentes, ej. Directo/Aceptado/Cedido → Producción
con signo) y/o T14 (selección de un solo "hecho" entre varios, ej. quedarse
solo con "Neto Retenido") usando los macros genéricos ya construidos:

- `macros/transformaciones/t13_reclasificar_componentes.sql`
- `macros/transformaciones/t14_seleccionar_hecho.sql`

Ambos macros ya existen y están probados de forma aislada (ver su
cabecera), pero **todavía no hay un modelo de cubo real que los use**,
porque no tenemos CSV real de un cubo con T13/T14 ni acceso a esa parte
de la base — se decidió explícitamente esperar esos datos reales en vez
de armar un caso sintético (ver conversación del Hito 2).

Candidatos del Plan Maestro de Cubos (`seeds/diccionario/plan_maestro_cubos.csv`)
que ya tienen T13 o T14 marcado:

- `S_BOSPVS46_000251` — Producción y Siniestros por Modalidad y Ramo (T13)
- `S_BOSPVS66_000254` — Producción y Siniestros por Modalidad, Ramo y
  Compañía (T14)

## Qué se necesita para completar esta prueba

1. El/los CSV real(es) de salida de uno de esos cubos (o de cualquier otro
   cubo con T13/T14 marcado en el Plan Maestro).
2. Las tablas fuente reales (o acceso a la base para inspeccionarlas) —
   igual que se hizo con el cubo 158 en `ejemplo1` [DBT-1].
3. Con eso: un `sources.yml`, un modelo de staging/intermedio que arme la
   columna "hecho" cruda, y un modelo mart que llame a
   `t13_reclasificar_componentes` / `t14_filtro_hecho` con los parámetros
   de ese cubo — mismo patrón que `models/cubo_158/`.

Cuando lleguen esos datos, esta carpeta se reemplaza por
`models/cubo_<n>/` siguiendo la guía de "Cómo agregar un cubo nuevo" del
README principal de `dbt_transformaciones/`.
