# [DBT-3] — pendiente de datos reales (T16)

Esta rama es la **prueba DBT-3** del informe Hito 2: validar T16
(enriquecimiento con código y/o jerarquía mediante catálogo de negocio,
ej. agregar "orden Administración" + "Departamento" a partir de un catálogo
externo, sin reemplazar ninguna columna existente) usando el macro genérico
ya construido:

- `macros/transformaciones/t16_enriquecer_catalogo.sql`

El macro ya existe y está probado de forma aislada (ver su cabecera; de
hecho ya se usa de forma incidental en `ejemplo1` [DBT-1] para agregar
"Tipo Compañia de Seguros"), pero **todavía no hay un modelo de cubo real
dedicado a probar un catálogo jerárquico T16 "clásico"** (con más de un
nivel u "orden"), porque no tenemos CSV real de ese tipo de cubo — se
decidió explícitamente esperar esos datos reales en vez de armar un caso
sintético (ver conversación del Hito 2).

Candidatos del Plan Maestro de Cubos (`seeds/diccionario/plan_maestro_cubos.csv`)
que ya tienen T16 marcado:

- `SPIM_0170_PSCS` — Producción y Siniestros por Tipo de Seguros y
  Compañía (catálogo 1-5 de "orden Modalidad Prod Siniestro")
- `SPIM_0202_ERCSGF` / `SPIM_0204_ERCSP` — Estado de Resultados (catálogo
  de "orden Cuenta" con subtotales)
- `S_BOFINR44_00387` — Indicadores Financieros (catálogo decide en qué
  Nv1 destino cae cada indicador)

## Qué se necesita para completar esta prueba

1. El/los CSV real(es) de salida de uno de esos cubos.
2. El catálogo de negocio real (código + jerarquía/orden) — igual que se
   hizo con `cat_compania_aps_158.csv` en `ejemplo1` [DBT-1].
3. Con eso: un `sources.yml`, un modelo intermedio, y un mart que llame a
   `t16_join_catalogo` con los parámetros de ese cubo — mismo patrón que
   `models/cubo_158/`.

Cuando lleguen esos datos, esta carpeta se reemplaza por
`models/cubo_<n>/` siguiendo la guía de "Cómo agregar un cubo nuevo" del
README principal de `dbt_transformaciones/`.
