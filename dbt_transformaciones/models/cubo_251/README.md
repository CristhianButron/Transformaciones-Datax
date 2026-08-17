# [DBT-2] Cubo 251 (S_BOSPVS46_000251) — T13, validado contra datos reales

Prueba DBT-2 del informe Hito 2: T13 (reclasificación de componentes con
signo). A diferencia de `ejemplo1` [DBT-1], acá se tuvo acceso tanto al
**CSV final real** (`207_datos_P.csv`) como a la **tabla fuente real**
(`data_d_bo_000000447_25`, 4.098 filas, ventana 2024-04 a 2026-05), así
que se pudo construir y validar el pipeline de punta a punta con datos
genuinamente independientes (no una corrida sintética como el primer
intento del 158).

## Qué se encontró en la fuente real

La columna `nv1` de la fuente mezcla **tipo** (Producción/Siniestros) y
**hecho** en un solo texto (`"Producción Directa Neta Anulaciones"`,
`"Siniestros por Reaseguro Aceptado"`, ...), con 10 valores distintos —
5 por Producción, 5 por Siniestros. De esos 5, solo 3 son componentes
reales (Directo, Reaseguro Aceptado, Reaseguro Cedido); los otros 2 son
agregados derivados que T13 descarta. Confirmado **exacto** contra una
fila real (Seguros Generales, Incendio, 2025-02-28):

| nv1 | valor |
|---|---|
| Producción Directa Neta Anulaciones (Directo) | 7.218.000 |
| Producción Aceptada en Reaseguro (Reaseguro Aceptado) | 1.226.000 |
| Producción Cedida a Reaseguro (Reaseguro Cedido) | 5.275.000 |
| Producción Total Suscrita | 8.444.000 = 7.218.000 + 1.226.000 ✓ (descartado) |
| Producción Neta Retenida | 3.168.000 ≈ 7.218.000 + 1.226.000 − 5.275.000 (descartado) |

El signo de "Reaseguro Cedido" es negativo en el 97% de las filas no
nulas de la fuente (el resto son anomalías reales puntuales, mismo
patrón que ya documenta el Diccionario para otros cubos — no se corrigen).

## T4: acá la tasa de cambio NO es fija

A diferencia del cubo 158 (USD→Bs × 6.86 constante), este cubo tiene
datos desde 2004 y el CSV real revela que el tipo de cambio varió mes a
mes hasta fijarse en 6.86 recién desde 2012 (8.04 en dic-2005, bajando
gradual hasta 6.86). Se armó `seeds/catalogos/cat_tasa_cambio_251.csv`
(266 filas, año+mes → tasa) **derivado directamente** del propio CSV real
(cociente Bs/US$ de cada fila), con consistencia del 100% dentro de cada
mes (0 meses con más de un valor de tasa distinto). El macro
`t4_convertir_moneda` ya soportaba una tasa variable vía columna/join, así
que no hizo falta tocarlo.

## T9: catálogo de ramo con llave compuesta (nuevo)

El mismo ramo crudo se traduce distinto según la modalidad — confirmado
con datos reales, no supuesto: `"Salud o Enfermedad"` → `"Salud o
Enfermedad"` bajo Seguros Generales, pero → `"Salud o enfermedad"`
(minúscula) bajo Seguros de Personas/Servicios de Pre-Pago; mismo patrón
con `"Accidentes Personales"`. El macro `t9_join_catalogo` original solo
soportaba una columna de llave — se agregó `t9_join_catalogo_compuesto`
en `macros/transformaciones/t9_diccionario_negocio.sql` para este caso.

⚠ `cat_ramo_aps_251.csv` **no es el mismo catálogo** que
`cat_ramo_aps_158.csv` aunque comparten casi todos los valores — con
evidencia real: `"Vitalicios"` → `"Seguros Vitalicios"` acá, pero se deja
igual en el 158. Confirma otra vez la advertencia del Diccionario (T9:
"los catálogos no son universales entre cubos").

Un ramo queda sin mapear a propósito por evidencia insuficiente (4 filas,
50/50 entre dos destinos posibles): *"Caución a Primer Requerimiento para
el Pago Diferido de Tributos Aduaneros de Importación"*.

## Validación

`dbt seed` + `dbt run` contra Postgres real, cargando la tabla fuente real
completa (4.098 filas) y comparando las 1.236 filas de `resultado_251`
contra el CSV real (`207_datos_P.csv`) fila por fila, por llave
(Año, Mes, Tipo de Seguro, Ramo, Componente):

**1.230 de 1.236 filas (99,5%) coinciden exactas en las 4 columnas de
valor** (Producción/Siniestros × Bs/US$). Las 6 diferencias restantes
tienen causa identificada, no son errores de la lógica de transformación:

- 4 filas (Seguros Previsionales, noviembre/diciembre 2024): el CSV real
  trae Producción = 0 explícito para combinaciones donde la fuente
  simplemente no tiene ninguna fila de Producción (solo de Siniestros) —
  el CSV real completa la grilla con ceros donde la fuente no tiene dato;
  esta corrida no inventa esos ceros.
- 2 filas ("Caución a Primer Requerimiento...", el ramo sin catálogo
  confirmado): la fuente trae la fila con valor 0, el CSV real no la
  trae — mismo patrón "0 vs ausencia de fila" que documenta el
  Diccionario en T10, sin una regla universal confirmada todavía.

## Cómo correrlo

Mismos pasos que `ejemplo1` [DBT-1] (ver el README de
`dbt_transformaciones/`), seleccionando este cubo:

```powershell
cd dbt_transformaciones
dbt seed
dbt run --select cubo_251
```

⚠ El nombre de la tabla fuente (`aps_raw_251.data_d_bo_000000447_25` en
`models/cubo_251/staging/sources.yml`) se infirió por convención con el
cubo 158 a partir del report_code real del Plan Maestro
(`D_BO_000000447_25`) — confirmar contra la base real antes de producción.
