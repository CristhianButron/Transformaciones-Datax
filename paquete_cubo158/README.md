# Cubo S_BOAPS_44_000620 (CSV 158) — modelo dbt Core real

Este proyecto construye el resultado del cubo a partir de tus 18 tablas reales
(`aps."DATA_D_BO_000000447_01"` a `_18`) usando las transformaciones documentadas
en el Diccionario: T1, T3, T4, T6, T7, T8, T9, T10, T11.

## Cómo correrlo

1. En Windows, creá y activá un entorno virtual local para que el comando `dbt` exista en esta carpeta:
   ```powershell
   cd dbt_158
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install dbt-postgres
   ```

2. Editá `~/.dbt/profiles.yml` (o creálo si no existe) con la conexión a TU base real:
   ```yaml
   cubo_158:
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

3. El `profile` que usa este proyecto se llama `cubo_158` (está definido en
   `dbt_project.yml`). Si tu tabla no está en el schema `aps`, editá
   `models/staging/sources.yml`.

4. Correr:
   ```bash
   cd dbt_158
   dbt seed     # carga el catalogo de companias
   dbt run      # ejecuta los 3 modelos (staging, intermedio, final)
   ```

5. El resultado final queda en la tabla **`resultado_158`** (schema `public` por
   defecto), con columnas: `departamento, modalidad, ramo, compania, anio, mes_num,
   fecha, produccion_usd, produccion_bs, siniestros_usd, siniestros_bs`.

## Qué verificar antes de confiar en el resultado (importante)

1. **Huecos en la serie mensual.** El T6 (desacumulación) usa `LAG()` ordenado por
   fecha dentro de cada año — si a una combinación Departamento+Ramo+Compañía le
   falta un mes, ese hueco se "absorbe" silenciosamente en el mes siguiente sin
   ningún error. Correr esto para detectar huecos reales:
   ```sql
   -- cuenta cuantos meses distintos hay por combinacion y anio; deberia dar 12
   -- (o el numero de meses que corresponda si el anio no esta completo)
   SELECT departamento, ramo, compania, anio, count(distinct mes_num) as meses
   FROM resultado_158
   GROUP BY 1,2,3,4
   HAVING count(distinct mes_num) < 12
   ORDER BY meses;
   ```

2. **Catálogo de compañías (T9).** El archivo `seeds/cat_compania.csv` es el mismo
   catálogo que ya confirmamos para el cubo S_BOSPVS66_000260 (CSV 189) — pero en el
   Hito 1 encontramos que los catálogos **no son universales entre cubos**. Antes de
   confiar en este, correr:
   ```sql
   SELECT DISTINCT nv2 FROM aps."DATA_D_BO_000000447_01"
   UNION SELECT DISTINCT nv2 FROM aps."DATA_D_BO_000000447_02"
   -- (repetir para las 18, o hacerlo con el macro union_18_reportes en dbt)
   ORDER BY 1;
   ```
   y comparar cada código contra lo que espera este cubo específico.

3. **T2 (pivot) no se aplicó.** En el Diccionario este cubo tenía T2 marcado, pero
   con los datos que revisamos `metrica`/`unidad_metrica` siempre son
   `moneda`/`USD` — no encontramos otra dimensión que pivotear. Si más adelante
   aparece otro valor de `metrica` en alguna de las 18 tablas, avisame para
   ajustar el modelo.

4. **Nombre del mes en español.** El modelo actual deja `mes_num` como número
   (1-12). Si el CSV final necesita el mes en letras (como en los demás cubos
   del proyecto: "Enero", "Febrero"...), hay que agregar esa traducción — no lo
   incluí porque no tenemos el CSV 158 real para confirmar el formato exacto
   esperado (¿"Enero"? ¿"ENE"? ¿con tilde?).

5. **Filas con valor NULL o vacío.** Los datos que me pasaste no tenían ningún
   caso de `-` o vacío, pero otros departamentos podrían tenerlo (T10). El modelo
   actual no filtra nada — si aparecen NULLs en `valor`, se van a propagar como
   NULL hasta el resultado final. Agregar un `WHERE valor IS NOT NULL` en
   `stg_produccion_siniestros.sql` si hace falta.

