# Transformaciones-Datax

Repositorio donde se prueban distintas tecnologías de transformación de
datos para elegir la mejor para el proyecto Data Transformation
Architecture (DTA). Cada tecnología evaluada en el informe **Hito 2** tiene
su propia rama, etiquetada con el mismo código que usa ese informe.

## Mapa de pruebas (Hito 2)

| Rama | Tag | Tecnología | Qué prueba |
|---|---|---|---|
| [`ejemplo1`](../../tree/ejemplo1) | **[DBT-1]** | dbt Core | Cubo 158 real (T1,T3,T4,T6,T7,T8,T9,T10,T11,T12) — transformación estructural y numérica |
| [`dbt-2`](../../tree/dbt-2) | **[DBT-2]** | dbt Core | T13/T14 — selección y reclasificación de "hechos" (pendiente de CSV real) |
| [`dbt-3`](../../tree/dbt-3) | **[DBT-3]** | dbt Core | T16 — catálogos y jerarquías (pendiente de CSV real) |
| [`sqlmesh-1`](../../tree/sqlmesh-1) | **[SM-1]** | SQLMesh | Réplica funcional del cubo 158 (mismo caso que DBT-1) |
| [`sqlmesh-2`](../../tree/sqlmesh-2) | **[SM-2]** | SQLMesh | Flujo de ambientes virtuales y plan/apply sobre el cubo 158 |
| [`hop-1`](../../tree/hop-1) *(esta rama)* | **[HOP-1]** | Apache Hop | Pipeline visual para un subconjunto del cubo 158 |

Cada rama tiene su propio README con los pasos exactos para correrla. El
resultado de esta comparación está documentado en el informe
`Hito 2 - Evaluación Técnica y Selección de la Tecnología de Procesamiento`.

## Esta rama: [HOP-1] — Apache Hop, pipeline visual para un subconjunto del cubo 158

El proyecto es [`hop_transformaciones/`](hop_transformaciones/): un
pipeline visual de Apache Hop (`.hpl`) que replica T1, T3, T4, T8 y T9 del
mismo cubo real (`S_BOAPS_44_000620`) sobre un subconjunto de 2 de las 18
tablas fuente. Se ejecutó de verdad con `hop-run` contra Postgres real
(no solo se diseñó) — ver el README de esa carpeta para el detalle de qué
se probó, qué quedó fuera de alcance a propósito (T2/T6/T11), cómo se
construyó sin la GUI en este entorno, y cómo correrlo paso a paso con la
GUI o por consola.
