# [HOP-1] hop_transformaciones — pipeline visual para un subconjunto del cubo 158

**Prueba HOP-1** del informe Hito 2: un subconjunto representativo del
mismo cubo real (`S_BOAPS_44_000620`, CSV 158) que `ejemplo1` [DBT-1] y
`sqlmesh-1` [SM-1], implementado como pipeline visual de
[Apache Hop](https://hop.apache.org/) en vez de SQL.

Ver también `ejemplo1` [DBT-1], `dbt-2` [DBT-2], `dbt-3` [DBT-3],
`sqlmesh-1` [SM-1] y `sqlmesh-2` [SM-2].

## Qué se probó (ejecutado de verdad con `hop-run`, no solo diseñado)

Alcance deliberadamente acotado (2 de las 18 tablas fuente: Producción y
Siniestros de La Paz) para poder construir y validar el pipeline a mano,
sin la GUI de Hop (ver "Cómo se construyó" abajo). Cubre:

- **T3** (unión): transform `Append` combina las dos tablas fuente.
- **T1** (clasificación por patrón): transform `Formula` deriva `tipo`
  (Produccion/Siniestros) a partir de `titulo1`, igual que
  `t1_renombrar_patron` en dbt.
- **T8** (normalización de texto): transform `String operations` — trim
  del código de compañía, Title Case del departamento ("la PAZ" -> "La
  Paz").
- **T9** (catálogo de negocio): transform `Database lookup` contra la
  misma tabla de catálogo `cat_compania_aps_158` (mismo contenido que el
  seed de dbt/SQLMesh) — reemplaza el código crudo y agrega
  `tipo_compania` (T16, mismo mecanismo, ver nota en el README de
  `ejemplo1`).
- **T4** (moneda): mismo transform `Formula`, `Bs = USD x 6.86`.

**No incluido en esta prueba puntual** (documentado, no fabricado):
T6 (desacumulación) y T2/T11 (pivot Producción/Siniestros a columnas) no
se implementaron en este subconjunto — Hop los resolvería con los
transforms `Analytic Query` (soporta `LAG`/`LEAD` nativamente, ver
[documentación oficial](https://hop.apache.org/manual/latest/pipeline/transforms/analyticquery.html))
y `Group by`, respectivamente, pero no se construyeron ni probaron acá
por acotar el alcance de esta prueba puntual. El resultado de esta prueba
trae el valor **acumulado tal cual viene de la fuente** (no mensualizado)
y una fila por tipo (no pivoteado).

## Cómo se construyó (sin la GUI, headless)

Este entorno no tiene entorno gráfico, así que el pipeline (`.hpl`) se
escribió a mano en XML, no con el diseñador visual de Hop — algo que en
un uso normal NO harías (la GUI es justamente el punto fuerte de Hop).
Para eso:

1. Se descargó e instaló la distribución oficial completa de Apache Hop
   2.12.0 (`apache-hop-client-2.12.0.zip`, ~785 MB, incluye GUI + CLI).
2. Se armó la estructura de proyecto (`project-config.json`,
   `metadata/rdbms/aps_db.json` para la conexión Postgres,
   `metadata/pipeline-run-configuration/local.json`) siguiendo el mismo
   formato que los proyectos de ejemplo que trae la distribución oficial.
3. El `.hpl` se escribió calcando la estructura XML real de pipelines de
   ejemplo de Apache Hop (uno por cada transform usado: `TableInput`,
   `Append`, `Formula`, `StringOperations`, `SelectValues`, `DBLookup`,
   `TableOutput`), no inventada.
4. Se corrió con `hop-run.sh` contra un Postgres real, iterando sobre
   errores reales hasta que las 18 filas (13 Producción + 5 Siniestros)
   procesaron sin errores — incluyendo 3 problemas reales que solo
   aparecen corriéndolo de verdad (no se detectan solo mirando el XML):
   - La clave del objeto `rdbms` en el JSON de conexión tiene que ser el
     tipo de plugin (`POSTGRESQL`), no un nombre arbitrario — si no, Hop
     no puede resolver qué driver instanciar.
   - El transform `Formula` usa el parser de fórmulas de Excel de Apache
     POI: separador de argumentos `,` (coma), no `;` (punto y coma, que
     sí acepta LibreOffice Calc).
   - En `String operations`, dejar `out_stream_name` igual al
     `in_stream_name` NO reemplaza el campo en el mismo lugar — hay que
     dejarlo vacío para que sobreescriba el campo de entrada.

## Resultado real obtenido

18 filas procesadas sin errores. Verificado contra la base real (algunos
ejemplos, acumulado crudo sin desacumular):

| Departamento | Compañía | Tipo Compañía | Tipo | USD | Bs | Ramo | Fecha |
|---|---|---|---|---|---|---|---|
| La Paz | ALI | Seguros Generales y Fianzas | Produccion | 1000 | 6860.00 | Incendio | 2025-01-31 |
| La Paz | ALI | Seguros Generales y Fianzas | Siniestros | 200 | 1372.00 | Incendio | 2025-01-31 |
| La Paz | NAL-G | Seguros Generales y Fianzas | Produccion | 500 | 3430.00 | Fidelidad de Empleados | 2025-01-31 |
| Potosí | ALI | Seguros Generales y Fianzas | Produccion | 50 | 343.00 | Incendio | 2025-01-31 |

(mismo dataset sintético de prueba que `ejemplo1`/`sqlmesh-1`; catálogo
de compañía y conversión de moneda dan exactamente los mismos valores
que esas dos pruebas — confirma que T1/T3/T4/T8/T9 son equivalentes entre
las tres tecnologías).

## Cómo correrlo (paso a paso)

A diferencia de dbt y SQLMesh, Apache Hop es principalmente una
herramienta de **escritorio con GUI** (`hop-gui`) — el flujo normal es
abrir el pipeline ahí, no editar el `.hpl` a mano. `hop-run` (usado para
esta prueba) es la forma de ejecutarlo sin la GUI, útil para
automatización/scheduling.

1. **Descargar Apache Hop** (requiere Java 17+):
   [https://hop.apache.org/download/](https://hop.apache.org/download/)
   — bajar el paquete "Client" (incluye GUI y CLI) y descomprimirlo.

2. **Registrar este proyecto en tu instalación de Hop.** Con la GUI:
   `Tools > Projects > Add project`, apuntando la carpeta del proyecto a
   esta carpeta (`hop_transformaciones/`). O editando a mano
   `config/hop-config.json` de tu instalación de Hop, agregando una
   entrada en `projectsConfig.projectConfigurations` con `projectHome`
   apuntando a la ruta absoluta de esta carpeta (ver el propio
   `hop-config.json` de tu instalación para el formato exacto).

3. **Configurar la conexión a Postgres.** Editar
   `metadata/rdbms/aps_db.json` (o hacerlo desde la GUI, que la guarda
   encriptada) reemplazando `TU_HOST` / `TU_USUARIO` / `TU_PASSWORD` /
   `TU_BASE_REAL`.

4. **Abrir el pipeline en la GUI** (`hop-gui.sh` / `hop-gui.bat`) para
   verlo visualmente, o ejecutarlo directo por consola:
   ```bash
   cd <tu-instalacion-de-hop>
   ./hop-run.sh --project transformaciones-datax \
     --file /ruta/a/hop_transformaciones/pipelines/hop1_cubo158_subset.hpl \
     --runconfig local
   ```
   (en Windows: `hop-run.bat` con los mismos parámetros).

5. **Ver el resultado:** queda en la tabla `hop1_resultado_158_subset` de
   tu base Postgres (la crea `TableOutput`, pero la tabla destino con las
   columnas correctas debe existir antes de correrlo — ver el DDL
   comentado al final de `pipelines/hop1_cubo158_subset.hpl`, o crearla
   desde la GUI con el botón "SQL" del transform de salida).
