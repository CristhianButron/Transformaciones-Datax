# [SM-2] sqlmesh_transformaciones — ambientes virtuales y flujo plan/apply

**Prueba SM-2** del informe Hito 2: mismo proyecto que `sqlmesh-1` [SM-1]
(réplica del cubo 158), pero el foco de esta prueba es específicamente el
diferenciador que el informe le atribuye a SQLMesh en la sección 3.2:
**ambientes virtuales aislados y flujo plan → apply**, algo que dbt Core
no tiene de forma nativa.

Ver también `ejemplo1` [DBT-1], `dbt-2` [DBT-2], `dbt-3` [DBT-3],
`sqlmesh-1` [SM-1] y `hop-1` [HOP-1].

## Qué se probó (ejecutado de verdad, no solo descrito)

Escenario: la tasa de cambio USD→Bs sube de 6.86 a 6.96 (hipotético).
Se quiere probar el impacto de ese cambio **sin tocar producción**, y
recién promoverlo cuando el resultado se validó.

1. **Estado inicial en `prod`** con la tasa vieja (6.86):
   ```
   sqlmesh plan --auto-apply
   ```
   `resultado_158` en el schema `sqlmesh_cubo158` (prod) queda con
   Producción Bs = 6860.00 para una fila de 1000 USD.

2. **Se edita el modelo** `models/resultado_158.sql`, tasa 6.86 → 6.96.

3. **Se previsualiza el cambio en un ambiente `dev` aislado**, sin tocar
   `prod`:
   ```
   sqlmesh plan dev --auto-apply
   ```
   SQLMesh detectó el cambio solo (diff real de la corrida):
   ```diff
   -    ROUND(d.valor_usd_mensual * 6.86, 2) AS valor_bs_mensual
   +    ROUND(d.valor_usd_mensual * 6.96, 2) AS valor_bs_mensual
   ```
   y **solo reconstruyó `resultado_158`** — no tocó `stg_cubo_158`,
   `int_cubo_158_desacumulado` ni los catálogos, porque el resto del DAG
   no cambió. Quedó en el schema `sqlmesh_cubo158__dev`.

4. **Verificación de aislamiento real** (misma fila, mismo momento, dos
   schemas distintos):

   | Ambiente | Schema | Producción US$ | Producción Bs |
   |---|---|---|---|
   | `prod` (sin el cambio) | `sqlmesh_cubo158` | 1000 | **6860.00** |
   | `dev` (con el cambio) | `sqlmesh_cubo158__dev` | 1000 | **6960.00** |

   `prod` y `dev` conviven en la misma base con datos distintos al mismo
   tiempo — nadie que esté consultando `sqlmesh_cubo158.resultado_158`
   ve el cambio hasta que se promueve.

5. **`sqlmesh environments`** confirma los dos ambientes activos, con
   `dev` marcado para expirar solo (limpieza automática) y `prod` sin
   expiración:
   ```
   prod - No Expiry
   dev - 2026-08-24 00:00:00
   ```

6. **Promoción a producción**, una vez validado el cambio en `dev`:
   ```
   sqlmesh plan --auto-apply
   ```
   SQLMesh mostró el mismo diff sobre `prod` y hay que fijarse en esta
   línea del log real de la corrida:
   ```
   SKIP: No physical layer updates to perform
   ```
   — es decir, **no volvió a calcular nada**: reutilizó la tabla que ya
   había construido y validado en `dev`, y promovió el ambiente a `prod`
   solo repuntando la capa virtual. `resultado_158` en `prod` pasó a
   6960.00 sin recomputar.

## Por qué importa esto para el proyecto DTA

dbt Core puede lograr algo similar con schemas de desarrollo separados
por `target`/`profile` y `dbt build --target dev`, pero es una convención
que arma el equipo, no un concepto de primera clase del framework. En
SQLMesh, "ambiente" es un concepto nativo: el mismo comando (`sqlmesh
plan <env>`) crea/actualiza cualquier ambiente aislado, calcula solo lo
que cambió, y promoverlo a producción no repite trabajo si ya se validó
en otro ambiente. Es la razón por la que el informe Hito 2 (sección 5,
matriz de evaluación) le da a SQLMesh el puntaje más alto en "Control de
cambios, preview y versionado".

Por qué esto solo no cambia la recomendación final del informe: ver
sección 6 y 11 del Hito 2 — el resto del proyecto (catálogo T1-T16 amplio,
reutilización vía macros, ecosistema) sigue pesando a favor de dbt Core.

## Cómo correrlo (paso a paso, Windows / PowerShell)

Mismos pasos 1-3 que `sqlmesh-1` [SM-1] (instalar, `config.yaml`,
pararse en la carpeta `sqlmesh_transformaciones`). Para reproducir esta
prueba puntual:

```powershell
# 1. Estado inicial en prod
sqlmesh plan --auto-apply

# 2. Editar models/resultado_158.sql (cambiar la tasa 6.86 por otro valor,
#    ya viene así en esta rama para que puedas probarlo directo)

# 3. Previsualizar en un ambiente aislado
sqlmesh plan dev --auto-apply

# 4. Comparar los dos schemas en tu cliente de Postgres:
#      select * from sqlmesh_cubo158.resultado_158;       -- prod, sin el cambio
#      select * from sqlmesh_cubo158__dev.resultado_158;  -- dev, con el cambio

# 5. Ver los ambientes activos
sqlmesh environments

# 6. Promover el cambio a producción
sqlmesh plan --auto-apply
```
