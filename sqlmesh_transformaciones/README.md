# [SM-1] sqlmesh_transformaciones — réplica funcional del cubo 158 en SQLMesh

**Prueba SM-1** del informe Hito 2 (Evaluación Técnica y Selección de la
Tecnología de Procesamiento): mismo caso que `ejemplo1` [DBT-1] — el cubo
real `S_BOAPS_44_000620` (CSV 158) — pero implementado en
[SQLMesh](https://sqlmesh.readthedocs.io/) en vez de dbt Core, para poder
comparar ambas tecnologías sobre el mismo problema real.

Ver también `dbt-2` [DBT-2], `dbt-3` [DBT-3], `ejemplo1` [DBT-1],
`sqlmesh-2` [SM-2] (ambientes y plan/apply) y `hop-1` [HOP-1].

## Qué se replicó

Los mismos 3 pasos que `ejemplo1`/`dbt_transformaciones/models/cubo_158/`:
`stg_cubo_158` → `int_cubo_158_desacumulado` → `resultado_158`, con las
mismas transformaciones (T1, T2, T4, T6, T7, T8, T9, T11, T16) y las
mismas columnas/orden de salida.

Diferencia deliberada frente a dbt: acá la unión de las 18 tablas fuente
(T3) se escribió explícita, en vez de con un macro genérico reutilizable
como `t3_union_fuentes` de dbt — SQLMesh también soporta macros
Python/SQL propios para este mismo patrón, pero para esta prueba puntual
se priorizó comparar el modelo de ejecución (planes, ambientes, motor)
antes que reconstruir toda la librería de macros T1-T16. Ver la sección
correspondiente del informe Hito 2 para la discusión de esta diferencia.

## Validación

Se corrió `sqlmesh plan dev --auto-apply` contra una base Postgres real,
con las 18 tablas fuente y las mismas filas sintéticas de prueba usadas
para validar `ejemplo1` [DBT-1] (departamento en mayúsculas mezcladas,
código de compañía con espacios, catálogo de compañía y de ramo, 3 meses
de acumulado, y 8 departamentos distintos para probar el orden de salida).

**Resultado: los 13 registros de `resultado_158` coinciden exactamente
(mismas columnas, mismos valores, mismo orden) con lo que produce dbt
en `ejemplo1` [DBT-1]** sobre el mismo dataset de prueba — confirma
paridad funcional entre ambas tecnologías para este caso.

## Cómo correrlo (paso a paso, Windows / PowerShell)

1. **Instalar SQLMesh** (requiere Python; el adaptador de Postgres
   necesita `psycopg2`):
   ```powershell
   pip install psycopg2-binary
   pip install sqlmesh
   sqlmesh --version
   ```

2. **Pararse en la carpeta del proyecto:**
   ```powershell
   cd Transformaciones-Datax\sqlmesh_transformaciones
   ```

3. **Configurar la conexión.** A diferencia de dbt (que usa un
   `profiles.yml` en la carpeta de usuario, fuera del repo), SQLMesh lee
   la conexión de `config.yaml` **dentro** del proyecto — por eso este
   archivo trae valores de ejemplo (`TU_HOST`, `TU_USUARIO`, etc.) que hay
   que reemplazar por los datos reales de Postgres antes de correrlo, o
   bien duplicar el archivo como `config.local.yaml` con las credenciales
   reales (ese nombre ya está en `.gitignore`, no se sube a git) y correr
   `sqlmesh` apuntando a él con `-p .` una vez renombrado a `config.yaml`
   localmente.
   ```powershell
   notepad config.yaml
   ```

4. **Generar el plan** (SQLMesh compara el estado local contra la base y
   muestra qué va a crear/cambiar antes de aplicar nada — este es el
   flujo "plan → apply" que dbt no tiene de forma nativa):
   ```powershell
   sqlmesh plan
   ```
   Va a pedir confirmación para aplicar los cambios (a diferencia de
   `dbt run`, que ejecuta directo). Para aplicar sin que pregunte:
   ```powershell
   sqlmesh plan --auto-apply
   ```

5. **Ver el resultado:** queda en la tabla `sqlmesh_cubo158.resultado_158`
   (en el ambiente `prod`; si corriste `sqlmesh plan dev` en cambio de
   `sqlmesh plan`, va a estar en el schema `sqlmesh_cubo158__dev`, ver
   siguiente sección).

## Sobre el flujo plan/apply y los "ambientes" (preview de SM-2)

A diferencia de `dbt run` (que aplica los cambios directo al schema de
producción configurado), SQLMesh separa explícitamente **plan** (mostrar
qué va a cambiar) de **apply** (aplicarlo), y permite mandar ese plan a un
ambiente aislado antes de tocar producción:

```powershell
sqlmesh plan dev --auto-apply     # crea/actualiza un ambiente de prueba "dev"
sqlmesh plan                       # compara contra "prod" y aplica ahí
```

La rama `sqlmesh-2` [SM-2] profundiza en este flujo (por qué es el
diferenciador principal de SQLMesh frente a dbt, según la sección 3.2 del
informe Hito 2).
