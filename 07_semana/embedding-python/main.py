"""Puebla documentos.embedding con vectores reales de gemini-embedding-001.

Caso de uso real para el Bloque 3 (pgvector) del módulo Semana 7: lee las filas
de `documentos` que todavía no tienen embedding, les pide un vector a Gemini y
lo guarda en la columna VECTOR(768) vía UPDATE.

Uso:
    uv run load_embeddings.py
"""

from __future__ import annotations

import os
import time

import psycopg
from dotenv import load_dotenv
from google import genai
from google.genai import errors, types
from psycopg.types.json import Json

from logger import get_logger

load_dotenv()

logger = get_logger()

MODEL_NAME = "gemini-embedding-001"
OUTPUT_DIMENSIONALITY = 768  # debe coincidir con VECTOR(768) en el schema
MAX_RETRIES = 5
RATE_LIMIT_HTTP_CODE = 429


def get_pending_documents(conn: psycopg.Connection, *, limit: int) -> list[tuple[int, str]]:
    """Devuelve (id, contenido) de documentos sin embedding todavía."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id, contenido FROM documentos WHERE embedding IS NULL ORDER BY id LIMIT %s",
            (limit,),
        )
        return cur.fetchall()


def embed_text(client: genai.Client, text: str) -> list[float]:
    """Genera un embedding de documento, reintentando ante rate limiting (429)."""
    config = types.EmbedContentConfig(
        task_type="RETRIEVAL_DOCUMENT",
        output_dimensionality=OUTPUT_DIMENSIONALITY,
    )
    
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            result = client.models.embed_content(model=MODEL_NAME, contents=text, config=config)
            return result.embeddings[0].values
        except errors.APIError as e:
            is_rate_limited = e.code == RATE_LIMIT_HTTP_CODE
            if not is_rate_limited or attempt == MAX_RETRIES:
                raise
            wait_seconds = 2**attempt
            logger.warning(
                "Rate limit (intento %d/%d). Reintentando en %ds", attempt, MAX_RETRIES, wait_seconds
            )
            time.sleep(wait_seconds)
    raise RuntimeError("No se pudo generar el embedding tras los reintentos")


def update_embedding(
    conn: psycopg.Connection, *, document_id: int, embedding: list[float], model_name: str
) -> None:
    """Guarda el embedding y deja registro del modelo usado en metadata."""
    vector_literal = "[" + ",".join(str(value) for value in embedding) + "]"
    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE documentos
            SET embedding = %s::vector,
                metadata = metadata || %s::jsonb
            WHERE id = %s
            """,
            (vector_literal, Json({"modelo": model_name}), document_id),
        )
    conn.commit()


def load_embeddings() -> None:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise RuntimeError("Falta DATABASE_URL en el entorno (revisá tu .env)")

    batch_limit = int(os.environ.get("EMBEDDING_BATCH_LIMIT", "50"))
    rate_limit_sleep = float(os.environ.get("RATE_LIMIT_SLEEP_SECONDS", "1.0"))

    # Client() toma GEMINI_API_KEY/GOOGLE_API_KEY, o las variables de Vertex AI
    # (GOOGLE_GENAI_USE_VERTEXAI, GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION)
    # si están seteadas en el entorno. No hace falta elegir el modo en el código.
    
    client = genai.Client()

    with psycopg.connect(database_url) as conn:
        pending = get_pending_documents(conn, limit=batch_limit)
        logger.info("Documentos pendientes de embedding: %d", len(pending))

        for document_id, contenido in pending:
            embedding = embed_text(client, contenido)
            update_embedding(conn, document_id=document_id, embedding=embedding, model_name=MODEL_NAME)
            logger.info("Embedding cargado id=%s (dim=%d)", document_id, len(embedding))
            time.sleep(rate_limit_sleep)  # cuidar el rate limit del free tier

        logger.info("Listo: %d documentos actualizados.", len(pending))


if __name__ == "__main__":
    load_embeddings()