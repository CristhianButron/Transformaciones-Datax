MODEL (
  name sqlmesh_cubo158.cat_compania_aps_158,
  kind SEED (
    path '../seeds/cat_compania_aps_158.csv'
  ),
  columns (
    raw_code TEXT,
    clean_code TEXT,
    tipo_compania TEXT
  )
);
