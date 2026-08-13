# Transformaciones-Datax

Repositorio donde realizare diferentes pruebas con cada una de las tecnologias que se probaran para hallar la mejor para las transformaciones.

## dbt Core: motor genérico de transformaciones

El proyecto principal es [`dbt_transformaciones/`](dbt_transformaciones/), un
proyecto dbt Core cuya lógica de transformación (T1–T16 del
`Diccionario_de_Transformaciones.xlsx`) está escrita **una sola vez** como
macros genéricos y reutilizables (`macros/transformaciones/`). Agregar un
cubo nuevo no requiere reescribir SQL de negocio (CASE de renombrado, LAG de
desacumulación, JOIN de catálogo) — solo declarar qué macros usa y con qué
parámetros. Ver el README de esa carpeta para el detalle de cada macro y
cómo agregar un cubo nuevo.

La rama [`ejemplo1`](../../tree/ejemplo1) conserva, sin modificar, la
primera prueba (`paquete_cubo158/`): el cubo 158 armado con SQL hardcodeado
específico para esa base, antes de generalizar el motor. Sirve como
referencia para comparar el "antes" (una implementación por cubo) contra el
"después" (macros compartidos + configuración por cubo).
