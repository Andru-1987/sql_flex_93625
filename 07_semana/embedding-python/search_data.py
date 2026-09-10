"""Búsqueda semántica de prueba: embebe una consulta real y la compara contra
los vectores ya cargados en documentos.embedding.

Uso:
    uv run search_documentos.py "como reseteo mi contraseña"
"""

from __future__ import annotations

import os
import sys

import psycopg
from dotenv import load_dotenv
from google import genai
from google.genai import types

from load_embeddings import MODEL_NAME, OUTPUT_DIMENSIONALITY
from logger import get_logger

load_dotenv()

logger = get_logger()

TOP_K = 5


def embed_query(client: genai.Client, query: str) -> list[float]:
    config = types.EmbedContentConfig(
        task_type="RETRIEVAL_QUERY",
        output_dimensionality=OUTPUT_DIMENSIONALITY,
    )
    result = client.models.embed_content(model=MODEL_NAME, contents=query, config=config)
    return result.embeddings[0].values


def search(conn: psycopg.Connection, *, query_embedding: list[float], top_k: int) -> list[tuple]:
    vector_literal = "[" + ",".join(str(value) for value in query_embedding) + "]"
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT contenido, 1 - (embedding <=> %s::vector) AS similitud
            FROM documentos
            WHERE embedding IS NOT NULL
            ORDER BY embedding <=> %s::vector
            LIMIT %s
            """,
            (vector_literal, vector_literal, top_k),
        )
        return cur.fetchall()


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit('Uso: uv run search_documentos.py "tu consulta"')

    query = sys.argv[1]
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise RuntimeError("Falta DATABASE_URL en el entorno (revisá tu .env)")

    client = genai.Client()

    with psycopg.connect(database_url) as conn:
        query_embedding = embed_query(client, query)
        resultados = search(conn, query_embedding=query_embedding, top_k=TOP_K)

    logger.info('Resultados para: "%s"', query)
    for contenido, similitud in resultados:
        print(f"[{similitud:.4f}] {contenido}")


if __name__ == "__main__":
    main()