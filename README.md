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
| [`sqlmesh-1`](../../tree/sqlmesh-1) *(esta rama)* | **[SM-1]** | SQLMesh | Réplica funcional del cubo 158 (mismo caso que DBT-1) |
| [`sqlmesh-2`](../../tree/sqlmesh-2) | **[SM-2]** | SQLMesh | Flujo de ambientes virtuales y plan/apply sobre el cubo 158 |
| [`hop-1`](../../tree/hop-1) | **[HOP-1]** | Apache Hop | Pipeline visual para un subconjunto del cubo 158 |

Cada rama tiene su propio README con los pasos exactos para correrla. El
resultado de esta comparación está documentado en el informe
`Hito 2 - Evaluación Técnica y Selección de la Tecnología de Procesamiento`.

## Esta rama: [SM-1] — SQLMesh, réplica funcional del cubo 158

El proyecto es [`sqlmesh_transformaciones/`](sqlmesh_transformaciones/):
la misma lógica de negocio del cubo 158 que `ejemplo1` [DBT-1], pero
implementada en SQLMesh en vez de dbt Core, para comparar ambas
tecnologías sobre el mismo problema real. Ver el README de esa carpeta
para el detalle de qué se replicó, cómo se validó (paridad exacta con
dbt sobre el mismo dataset de prueba) y cómo correrlo paso a paso.
