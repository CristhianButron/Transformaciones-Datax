# dbt_transformaciones — motor genérico de transformaciones

Este proyecto dbt Core reemplaza el enfoque anterior (un proyecto dbt
distinto, con SQL de negocio reescrito a mano, por cada cubo — ver la rama
`ejemplo1` para la versión original del cubo 158).

La idea: **la lógica de cada transformación (T1–T16 del
`Diccionario_de_Transformaciones.xlsx`) vive UNA sola vez**, como macro
genérico y parametrizado en `macros/transformaciones/`. Un cubo nuevo no
reimplementa esa lógica — solo declara, en un modelo corto, **qué** macros
usa y **con qué parámetros** (qué columna, qué tasa de cambio, qué catálogo,
qué partición). Eso es lo que hace que agregar el cubo 159 no obligue a
reescribir el CASE de renombrado, el LAG de desacumulación o el JOIN de
catálogo que ya se escribieron para el 158 — se reutilizan tal cual.

## Estructura

```
dbt_transformaciones/
  macros/transformaciones/   -> un archivo por Tx (t1_renombrar.sql, t4_moneda.sql, ...)
                                 cada uno documentado con su definición y
                                 advertencias tal como aparecen en el Diccionario.
  seeds/diccionario/         -> Índice, Plan Maestro de Cubos y Matriz de
                                 Clasificación del xlsx, versionados como CSV
                                 (fuente de verdad de qué Tx aplica a qué cubo).
  seeds/catalogos/           -> catálogos de negocio (T9/T16), uno por archivo.
                                 ⚠ un catálogo confirmado para un cubo NO es
                                 necesariamente válido para otro (ver T9) —
                                 el nombre del archivo indica para qué cubo(s)
                                 se confirmó.
  models/cubo_158/           -> primer cubo migrado a este patrón, de punta a
                                 punta, como prueba de que el motor reproduce
                                 exactamente el resultado de la versión
                                 hardcodeada (ver "Cómo se validó" abajo).
```

## Macros disponibles (uno por transformación del Diccionario)

| Código | Qué hace | Macro(s) |
|---|---|---|
| T1 | Renombrado 1 a 1 (valor, sin catálogo) | `t1_renombrar_exacto`, `t1_renombrar_patron` |
| T2 | Pivot (categoría → columna) | `t2_pivot_valor` |
| T3 | Unión / concatenación de N tablas | `t3_union_fuentes` |
| T4 | Conversión de moneda | `t4_convertir_moneda` |
| T5 | Cálculo simple entre columnas / offset de fecha | `t5_promedio`, `t5_offset_fecha` |
| T6 | Desacumulación (LAG dentro del ciclo) | `t6_desacumular` |
| T7 | Descomposición de fecha | `t7_anio`, `t7_mes_numero`, `t7_mes_nombre`, `t7_dia` |
| T8 | Normalización de texto | `t8_normalizar_texto` (modos: trim/titlecase/mayusculas/minusculas/sin_tildes_oracion) |
| T9 | Catálogo de negocio (reemplaza) | `t9_join_catalogo` |
| T10 | Eliminar filas (columnas: simplemente no se seleccionan) | `t10_filtro_filas_validas` |
| T11 | Columna nueva por combinación de fuentes | sin macro propio — es T3 + T2, ver `t11_combinar.sql` |
| T12 | Texto numérico con separador de miles + escala | `t12_parsear_numero` |
| T13 | Reclasificación de componentes (con signo) | `t13_reclasificar_componentes`, `t13_signo_componente` |
| T14 | Selección de un solo "hecho" | `t14_filtro_hecho` |
| T15 | Coma decimal → punto decimal | `t15_coma_a_punto` |
| T16 | Enriquecimiento con catálogo (agrega, no reemplaza) | `t16_join_catalogo` |

Cada archivo trae en la cabecera la definición y las advertencias exactas
de la hoja correspondiente del Diccionario (ej. T9: "los catálogos no son
universales entre cubos"; T6: "confirmar con 3+ periodos que el dato solo
crece"). Léelas antes de usarlos en un cubo nuevo — son las mismas
condiciones que hay que verificar con datos reales antes de aplicar la
transformación.

## Cómo se armó el cubo 158 con este patrón

`models/cubo_158/staging/stg_cubo_158.sql` → `int_cubo_158_desacumulado.sql`
→ `marts/resultado_158.sql`. Comparar contra la rama `ejemplo1`
(`paquete_cubo158/dbt_158/models/`) muestra el mismo resultado, pero ahí el
CASE, el LAG y el JOIN de catálogo estaban escritos a mano; acá son llamadas
a `t1_renombrar_patron`, `t6_desacumular`, `t9_join_catalogo`, etc. con los
parámetros de este cubo puntual.

### Cómo se validó

Se corrió `dbt seed` + `dbt run` contra una base Postgres real (no solo
`dbt compile`) con las 18 tablas fuente (16 vacías + 2 con filas
sintéticas: departamento en mayúsculas mezcladas, código de compañía con
espacios y con el catálogo, y 3 meses de acumulado para probar T6). El
resultado (`resultado_158`) dio exactamente los valores esperados a mano:

| fecha | produccion_usd | produccion_bs | siniestros_usd | siniestros_bs |
|---|---|---|---|---|
| 2025-01-31 | 1000 | 6860.00 | 200 | 1372.00 |
| 2025-02-28 | 800 | 5488.00 | 150 | 1029.00 |
| 2025-03-31 | 1200 | 8232.00 | 150 | 1029.00 |

(desacumulación correcta mes a mes, "la PAZ"/"La Paz" → "La Paz", código de
compañía con espacios → catálogo ALI-G → ALI, USD→Bs x 6.86, y Producción/
Siniestros combinados en la misma fila). Esto prueba que el motor genérico
reproduce la misma lógica de negocio que la versión hardcodeada, sin haber
reescrito esa lógica.

❌ Todavía NO se corrió contra el volumen real completo de las 18 tablas del
cubo 158 (eso sigue pendiente, igual que en la versión anterior — ver los
puntos de verificación que ya estaban documentados en `ejemplo1`, siguen
aplicando: huecos en la serie mensual, catálogo de compañía no universal,
T2 no aplicado en este cubo en particular, nombre de mes en letras si el
CSV final lo pide, filas con valor NULL).

## Cómo agregar un cubo nuevo

1. Revisar en `seeds/diccionario/plan_maestro_cubos.csv` (o en el
   Diccionario original) qué Tx aplican a ese cubo.
2. Si el cubo necesita un catálogo de negocio (T9/T16) que todavía no
   existe, agregarlo en `seeds/catalogos/` con un nombre que dejé claro
   para qué cubo se confirmó.
3. Crear `models/cubo_<n>/staging/sources.yml` con las tablas fuente.
4. Escribir el/los modelo(s) del cubo llamando a los macros de
   `macros/transformaciones/` con los parámetros de ESE cubo (columnas,
   tasa de cambio, partición de desacumulación, mapeo de renombrado, etc.).
   No se debería necesitar escribir un CASE, un LAG o un JOIN de catálogo
   a mano — si hace falta, es señal de que falta un macro genérico nuevo
   (agregarlo a `macros/transformaciones/`, no dentro del modelo del cubo).
5. Correr `dbt run --select cubo_<n>` y validar contra datos reales antes
   de dar el cubo por confirmado (los macros automatizan el CÓMO, no
   reemplazan la verificación del QUÉ — moneda, catálogo y tasa hay que
   seguir confirmándolos con ejemplos reales, tal como pide cada hoja del
   Diccionario).

## Cómo correrlo

```bash
cd dbt_transformaciones
python -m venv .venv && source .venv/bin/activate   # o .\.venv\Scripts\Activate.ps1 en Windows
pip install dbt-postgres

# ~/.dbt/profiles.yml
# transformaciones_datax:
#   target: dev
#   outputs:
#     dev:
#       type: postgres
#       host: TU_HOST
#       user: TU_USUARIO
#       password: TU_PASSWORD
#       port: 5432
#       dbname: TU_BASE_REAL
#       schema: public
#       threads: 4

dbt seed
dbt run
```
