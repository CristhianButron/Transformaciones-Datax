# [DBT-2] dbt_transformaciones — motor genérico de transformaciones

> **Prueba DBT-2** del informe Hito 2 (Evaluación Técnica y Selección de la
> Tecnología de Procesamiento). Escenario "T13 — reclasificación de
> componentes con signo", cubo real `S_BOSPVS46_000251` (CSV 207) — **✅
> validada con CSV y tabla fuente reales**, 99,5% de coincidencia exacta.
> Ver [`models/cubo_251/README.md`](models/cubo_251/README.md) para el
> detalle completo. El resto de este README (macros, cómo correrlo, cómo
> agregar un cubo) es el mismo proyecto que `ejemplo1` [DBT-1] — no se
> duplicó. Ver también `dbt-3` [DBT-3], `sqlmesh-1` [SM-1], `sqlmesh-2`
> [SM-2] y `hop-1` [HOP-1] para el resto de las pruebas comparadas en ese
> informe.

Este proyecto dbt Core reemplaza el enfoque original con SQL de negocio
reescrito a mano por cada cubo (esa primera versión hardcodeada del cubo
158 quedó reemplazada en esta misma rama por la versión genérica — ver el
historial de commits de `ejemplo1` si hace falta compararlas).

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

### Segunda vuelta: comparación contra el CSV real (`158_datos_P.csv`)

El usuario corrió este mismo pipeline contra la base real y mandó dos CSV:
el resultado real esperado (`158_datos_P.csv`, formato del CSV 158 oficial)
y lo que efectivamente devolvió `resultado_158` en esa corrida. Comparar
ambos (162.866 filas vs 18.873) permitió encontrar y corregir:

1. **Faltaba el catálogo de Ramo (T9)** — el ramo se pasaba tal cual venía
   de la fuente, pero el CSV oficial usa nombres distintos ("Incendio" →
   "Incendio y Aliados", "Fidelidad de Empleados" → "Fidelidad de
   empleado", etc.). Se agregó `seeds/catalogos/cat_ramo_aps_158.csv`
   (35 equivalencias) armado comparando los valores de ambos CSV por
   coincidencia de nombre — **no** verificado fila a fila contra la fuente
   cruda, como pide T9. Quedan 2 ramos vistos en el CSV real sin mapear a
   propósito, por falta de evidencia suficiente para decidir la
   equivalencia (ver el comentario en `stg_cubo_158.sql`).
2. **Faltaba "Tipo Compañia de Seguros" (T16)** — no existía en ningún
   archivo fuente, se obtiene de un catálogo por compañía (Generales y
   Fianzas / Personas). Se agregó como columna nueva a
   `cat_compania_aps_158.csv` en vez de crear un catálogo aparte, porque
   depende 1 a 1 de la misma compañía. Hay 4 compañías vistas en el CSV
   real (24S, LAT, PRO, ZUR) que no estaban en los datos usados para armar
   el catálogo original — no se adivinó su código crudo (nv2), así que hoy
   estas 4 quedan sin clasificar hasta confirmarlo.
3. **Nombres y orden de columnas** — `resultado_158` ahora usa exactamente
   los mismos encabezados que `158_datos_P.csv` (`Año`, `Mes`, `Departamento`,
   `Tipo Compañia de Seguros`, `Compañia de Seguros`, `Tipo Seguro`, `Ramo`,
   `Producción US$`, `Producción Bs`, `Siniestros US$`, `Siniestros Bs`) en
   vez de los nombres internos de trabajo. `Mes` ahora es el nombre en
   letras (T7), no el número.

Se volvió a correr `dbt seed` + `dbt run` contra Postgres real agregando
un segundo par de filas sintéticas (compañía `NAL-G`, modalidad "Servicios
de Prepago", ramo "Fidelidad de Empleados") para probar el catálogo de
ramo y el rename de modalidad al mismo tiempo que T6/T4/T9 ya probados.
Resultado exacto esperado en los 5 casos (ver commit).

⚠ **Dos cosas que NO se tocaron, a propósito, y quedan pendientes de que el
usuario las revise:**

- **Rango de fechas.** `158_datos_P.csv` tiene datos 2010–2026; la corrida
  real de `resultado_158` solo cubrió 2024-10 a 2026-05 (18 tablas fuente
  actuales). Es casi seguro que, igual que en el cubo de ADUANA
  (documentado en T3 del Diccionario), la base real solo tiene cargada una
  ventana reciente en esas 18 tablas, y el histórico completo necesita
  concatenar más extracciones/vintages — no es algo que se arregle en el
  SQL sin saber qué tablas históricas existen. Confirmar con el usuario
  antes de asumir cualquier solución.
- **Valores de "acumulado" que bajan de un mes a otro (T6).** Se detectaron
  183 de 18.873 filas (~1%) donde el valor mensual desacumulado da
  negativo — la mayoría porque enero (primer mes del ciclo) vino negativo
  tal cual en la fuente, y una minoría porque el acumulado bajó de un mes
  al siguiente. El Diccionario ya documenta casos así como anomalías reales
  puntuales en otros cubos (no un bug del cálculo) — no se "corrigió"
  forzando el valor a 0 porque eso podría estar ocultando una revisión de
  cifras real. Si el usuario confirma que debe tratarse distinto, ajustar
  `t6_desacumular` o agregar un `t10_filtro_filas_validas` en ese punto.

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

## Cómo correrlo (paso a paso, Windows / PowerShell)

1. **Instalar dbt** (una sola vez, requiere Python instalado):
   ```powershell
   pip install dbt-postgres
   dbt --version
   ```

2. **Crear el archivo de conexión `profiles.yml`.** Este archivo NO va en
   el repo (tiene tus credenciales) — vive en tu carpeta de usuario, en
   `.dbt`, separado del proyecto:
   ```powershell
   mkdir $env:USERPROFILE\.dbt
   notepad $env:USERPROFILE\.dbt\profiles.yml
   ```
   Pegar esto (el nombre `transformaciones_datax` tiene que calzar exacto
   con el `profile:` de `dbt_transformaciones/dbt_project.yml`):
   ```yaml
   transformaciones_datax:
     target: dev
     outputs:
       dev:
         type: postgres
         host: TU_HOST
         user: TU_USUARIO
         password: TU_PASSWORD
         port: 5432
         dbname: TU_BASE_REAL
         schema: public
         threads: 4
   ```
   Reemplazar `TU_HOST` / `TU_USUARIO` / `TU_PASSWORD` / `TU_BASE_REAL` por
   los datos reales de Postgres. Guardar y cerrar.

3. **Pararse en la carpeta del proyecto** (el `dbt_project.yml` está ahí
   adentro, no en la raíz del repo):
   ```powershell
   cd Transformaciones-Datax\dbt_transformaciones
   ```

4. **Cargar los catálogos** (los CSV de `seeds/` — equivalencias de
   compañía, ramo, y el diccionario de transformaciones versionado):
   ```powershell
   dbt seed
   ```

5. **Correr los modelos** (construye `stg_cubo_158` → `int_cubo_158_desacumulado`
   → `resultado_158` en tu base):
   ```powershell
   dbt run
   ```
   Para correr solo este cubo si hay más de uno en el proyecto:
   ```powershell
   dbt run --select cubo_158
   ```

6. **Ver el resultado:** queda en la tabla `resultado_158` del schema que
   pusiste en `profiles.yml` (`public` en el ejemplo de arriba).

Si algo falla, los errores más comunes son "Could not find profile" (el
`profiles.yml` no existe o el nombre no calza) y "No dbt_project.yml found"
(no estás parado en `dbt_transformaciones`, sino en la raíz del repo).
