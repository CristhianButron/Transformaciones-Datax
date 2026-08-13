{#
  T11 — Columna nueva creada por combinación de dos fuentes
  Diccionario_de_Transformaciones.xlsx, hoja T11.

  No tiene una forma SQL propia distinta de las demás: es la CONSECUENCIA
  de una unión (T3, ver t3_union_fuentes) o de un pivot (T2, ver
  t2_pivot_valor) entre 2+ archivos. Se documenta acá como referencia
  cruzada para que, al armar el config de un cubo nuevo, quede claro que
  "esta columna sale sola al combinar A+B" no necesita transformación
  aparte — solo union/join + t2_pivot_valor sobre el resultado combinado.

  Ejemplo de este proyecto (cubo 158): "siniestros_usd" no existe en ningún
  archivo de Producción ni de Siniestros por separado — aparece porque
  ambos grupos de archivos se concatenan (T3) y luego se pivotea (T2) por
  la columna "tipo" (Produccion/Siniestros). Ver models/cubo_158/marts/resultado_158.sql.
#}
