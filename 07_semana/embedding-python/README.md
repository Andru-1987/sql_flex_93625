# Embeddings reales con gemini-embedding-001 (Bloque 3 — pgvector)

Complemento práctico al módulo Semana 7: en vez de vectores aleatorios, esto
carga embeddings **reales** en `documentos.embedding` usando el modelo
`gemini-embedding-001` de Google, para que la búsqueda semántica del
Ejercicio 3.1 tenga sentido de verdad.

## Requisitos

- Haber corrido `semana7_setup.sql` (la tabla `documentos` ahora usa `VECTOR(768)` y
  las filas se insertan con `embedding = NULL`).
- [`uv`](https://docs.astral.sh/uv/) instalado.
- Una API key gratuita de Gemini: https://aistudio.google.com/apikey
  (alternativamente, credenciales de Vertex AI si preferís usar tu proyecto GCP — ver `.env.example`).

## Setup

```bash
cd embeddings
cp .env.example .env
# completar DATABASE_URL y GEMINI_API_KEY en .env
uv sync
```

## Uso

**1. Cargar embeddings pendientes:**

```bash
uv run load_embeddings.py
```

Busca las filas de `documentos` con `embedding IS NULL`, les pide un vector a
`gemini-embedding-001` (768 dimensiones, `task_type=RETRIEVAL_DOCUMENT`) y
las actualiza. Correrlo de nuevo no vuelve a gastar cuota: solo procesa lo
que sigue en `NULL`.

**2. Probar la búsqueda semántica con una consulta real:**

```bash
uv run search_documentos.py "como reseteo mi contraseña"
```

Este script embebe la consulta con `task_type=RETRIEVAL_QUERY` (task type
distinto al de los documentos — así lo recomienda Google para retrieval) y
corre el mismo `ORDER BY embedding <=> ...` del Ejercicio 3.1, pero contra un
vector con significado real en vez de uno aleatorio.

## Notas de diseño

- **Dimensión 768**: es una de las tres dimensiones "recomendadas" por Google
  para este modelo (las otras son 1536 y 3072, vía Matryoshka Representation
  Learning). Si cambiás `OUTPUT_DIMENSIONALITY` en `load_embeddings.py`, hay
  que recrear la columna (`ALTER TABLE documentos ALTER COLUMN embedding TYPE VECTOR(N)`)
  y el índice HNSW.
- **Gemini API vs. Vertex AI**: el mismo cliente (`genai.Client()`) sirve para
  las dos — que use una u otra depende solo de qué variables de entorno estén
  seteadas (ver `.env.example`). No hace falta tocar el código.
- **Rate limiting**: el free tier de la Gemini API tiene límites de
  requests por minuto. El loader duerme `RATE_LIMIT_SLEEP_SECONDS` entre
  documentos y reintenta con backoff exponencial ante un 429.
- **`gemini-embedding-001` procesa un texto a la vez** (no hay batch real en
  este endpoint), por eso el loop es secuencial en vez de mandar una lista.
- Los embeddings de `metadata_api`/`metadata` guardan qué modelo generó cada
  vector — útil si el día de mañana cambiás de modelo y necesitás saber qué
  filas re-embedear.