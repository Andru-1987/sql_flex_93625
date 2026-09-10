## Semana 7: PostgreSQL Moderno (JSONB y Extensiones AI)

PostgreSQL ha evolucionado de un motor relacional puro a una plataforma de datos híbrida capaz de manejar datos semi-estructurados, búsqueda semántica y cargas de trabajo de IA en producción.  A continuación, profundizo en cada uno de los cinco pilares del Módulo 7, integrando mejores prácticas técnicas, casos de uso reales y consejos de ingeniería para data engineers, DBAs, devs e IA engineers. [databricks](https://www.databricks.com/blog/what-is-pgvector)

***

## 1. Datos Semi-Estructurados con JSONB

### 1.1 Fundamentos Técnicos: JSON vs. JSONB

La diferencia crítica entre `JSON` y `JSONB` no es solo de rendimiento, sino de **modelo de almacenamiento interno**. [adhdecode](https://adhdecode.com/articles/postgres/postgres-jsonb-performance-tips/)

- **JSON (texto plano)**: Almacena el documento tal cual, preservando espacios, orden de llaves y formato. Cada consulta requiere *re-parsing* del texto completo.
- **JSONB (binario descompuesto)**: Convierte el JSON a una representación binaria interna que elimina espacios redundantes, ordena las llaves y descompone la estructura en nodos indexables.

**Regla profesional reforzada**: En 2026, **siempre usar JSONB** salvo casos muy específicos (ej. auditoría de logs donde el formato exacto importa). [adhdecode](https://adhdecode.com/articles/postgres/postgres-jsonb-performance-tips/)

### 1.2 Estrategia Híbrida de Diseño (Relacional + JSONB)

El patrón recomendado en producción es **columnas relacionales para integridad + JSONB para flexibilidad**. [adhdecode](https://adhdecode.com/articles/postgres/postgres-jsonb-performance-tips/)

```sql
CREATE TABLE pedidos_modernos (
    id UUID PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    fecha_pedido TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado TEXT NOT NULL CHECK (estado IN ('pendiente', 'enviado', 'entregado')),
    
    -- JSONB para atributos dinámicos
    detalles_envio JSONB NOT NULL DEFAULT '{}',
    metadata_api JSONB DEFAULT '{}'
);
```

**Por qué funciona**:
- Mantiene integridad referencial (FKs, constraints) en columnas nativas.
- Permite evolución del esquema sin migraciones costosas (ej. nuevos campos de APIs externas).
- Facilita consultas analíticas sobre campos estables (fecha, estado) mientras se mantiene flexibilidad en detalles variables.

### 1.3 Operadores JSONB y Patrones de Consulta

| Operador | Función | Tipo de Retorno | Uso Típico |
|----------|---------|-----------------|------------|
| `->` | Extrae clave como JSONB | `jsonb` | Navegación intermedia |
| `->>` | Extrae clave como texto | `text` | **Filtrado en WHERE** |
| `#>` | Extrae ruta anidada como JSONB | `jsonb` | Estructuras profundas |
| `#>>` | Extrae ruta anidada como texto | `text` | Comparaciones complejas |
| `@>` | Contención (¿contiene X?) | `boolean` | **Aceleración con GIN** |

**Ejemplo de producción** (e-commerce con filtros dinámicos):

```sql
-- Búsqueda eficiente con índice GIN
CREATE INDEX idx_pedidos_detalles_gin ON pedidos_modernos USING GIN (detalles_envio);

-- Consulta optimizada: usa el índice GIN con @>
SELECT id, usuario_id, detalles_envio->>'metodo' AS metodo_envio
FROM pedidos_modernos
WHERE detalles_envio @> '{"metodo": "Express", "es_fragil": true}';
```

**Tips de ingeniería**:
- **Evitar anidación excesiva**: Más de 4-5 niveles de profundidad degrada legibilidad y rendimiento. [adhdecode](https://adhdecode.com/articles/postgres/postgres-jsonb-performance-tips/)
- **Consistencia de tipos**: Si un campo puede ser `string` o `number`, normalizar en la aplicación antes de insertar.
- **Índices de expresión** para rutas frecuentes:
  ```sql
  CREATE INDEX idx_tema_usuario ON usuarios ((perfil->>'settings'->>'theme'));
  ```

### 1.4 Casos de Uso Reales en la Industria

- **Integración con APIs externas**: Stripe, Google Maps, Shopify devuelven JSONs variables. Almacenar en JSONB evita migraciones por cada cambio de API. [adhdecode](https://adhdecode.com/articles/postgres/postgres-jsonb-performance-tips/)
- **Catálogos de e-commerce**: Productos con atributos dinámicos (talla, color, material) que varían por categoría.
- **Logs de auditoría**: Eventos con estructuras diferentes pero que requieren consultas ad-hoc.
- **Configuraciones de usuario**: Preferencias, temas, notificaciones personalizadas.

***

## 2. Búsqueda de Texto Completo (Full-Text Search - FTS)

### 2.1 Limitaciones de LIKE y Por Qué FTS

El operador `LIKE '%palabra%'` es **O(n)** y no aprovecha índices (excepto en casos muy específicos con `LIKE 'prefijo%'`). [danielabaron](https://danielabaron.me/blog/speed-up-pg-fts-with-persistent-ts-vectors/)

**Problemas estructurales**:
- **Sequential Scan obligatorio**: Lee cada fila de la tabla.
- **Sin lingüística**: No detecta plurales, conjugaciones ni sinónimos.
- **Sin relevancia**: Todos los resultados son iguales, sin ranking.

### 2.2 Arquitectura FTS: tsvector y tsquery

**tsvector (documento procesado)**: Transforma texto en tokens normalizados mediante:
1. **Tokenización**: Divide en palabras.
2. **Normalización**: Minúsculas, eliminación de acentos.
3. **Stop words**: Elimina palabras sin valor semántico ("el", "de", "y").
4. **Lematización (stemming)**: Reduce a raíz ("corriendo" → "corr").

**Regla crítica**: Especificar siempre el idioma (`'spanish'`, `'english'`) para aplicar el diccionario correcto. [tacnode](https://tacnode.io/post/full-text-search-postgresql-complete-guide)

```sql
-- Transformación explícita
SELECT to_tsvector('spanish', 'Los ingenieros están corriendo rápidamente');
-- Resultado: 'corr':4 'ing':2 'rapid':5
```

**tsquery (consulta del usuario)**: Combina términos con operadores lógicos:
- `&` (AND): Ambos términos deben existir.
- `|` (OR): Al menos uno debe existir.
- `!` (NOT): Excluye el término.
- `<->` (FOLLOWED BY): Frase exacta u orden específico.

```sql
-- Consulta compuesta
SELECT to_tsquery('spanish', 'ingeniero & correr');
```

### 2.3 Operador @@ y Ranking con ts_rank()

El operador `@@` evalúa si un `tsvector` coincide con un `tsquery`. [supaexplorer](https://supaexplorer.com/best-practices/supabase-postgres/advanced-full-text-search/)

```sql
-- Búsqueda básica
SELECT titulo, contenido
FROM articulos
WHERE to_tsvector('spanish', contenido) @@ to_tsquery('spanish', 'recetas & pollo');
```

**Ranking de relevancia**: `ts_rank()` asigna puntuación basada en frecuencia y posición de términos. [tacnode](https://tacnode.io/post/full-text-search-postgresql-complete-guide)

```sql
SELECT 
    titulo,
    ts_rank(to_tsvector('spanish', contenido), to_tsquery('spanish', 'recetas & pollo')) AS relevancia
FROM articulos
WHERE to_tsvector('spanish', contenido) @@ to_tsquery('spanish', 'recetas & pollo')
ORDER BY relevancia DESC
LIMIT 10;
```

**Mejora**: Usar `ts_rank_cd()` (cover density) cuando la proximidad entre términos importa (búsquedas multi-palabra). [tacnode](https://tacnode.io/post/full-text-search-postgresql-complete-guide)

### 2.4 Optimización con Columnas Generadas e Índices GIN

**Problema**: Calcular `to_tsvector()` en cada consulta es costoso.

**Solución**: Columna generada almacenada (`STORED`) + índice GIN. [danielabaron](https://danielabaron.me/blog/speed-up-pg-fts-with-persistent-ts-vectors/)

```sql
ALTER TABLE articulos
ADD COLUMN search_idx TSVECTOR 
GENERATED ALWAYS AS (to_tsvector('spanish', contenido)) STORED;

CREATE INDEX idx_fts_articulos ON articulos USING GIN (search_idx);
```

**Resultado**: Consultas que tomaban 2+ segundos con `ILIKE` ahora completan en **10-50ms**. [supaexplorer](https://supaexplorer.com/best-practices/supabase-postgres/advanced-full-text-search/)

**Tips de producción**:
- **Multilingüe**: Almacenar el idioma en una columna y usar configuraciones dinámicas. [stackharbor](https://stackharbor.com/en/knowledge-base/pg-full-text-search-tsvector/)
- **Tuning GIN para alta escritura**:
  ```sql
  ALTER TABLE articulos SET (gin_pending_list_limit = '16MB');
  ```
- **Mantenimiento**: Programar `REINDEX INDEX CONCURRENTLY` trimestralmente en tablas muy activas (GIN sufre bloat). [stackharbor](https://stackharbor.com/en/knowledge-base/pg-full-text-search-tsvector/)

### 2.5 Búsqueda Híbrida: FTS + Vectores (RAG)

En pipelines RAG, combinar FTS (palabras exactas) + búsqueda vectorial (significado) mejora la recuperación. [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

**Patrón RRF (Reciprocal Rank Fusion)**:

```sql
WITH semantic AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> :query_vec) AS rank
    FROM documentos
    ORDER BY embedding <=> :query_vec
    LIMIT 40
),
lexical AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_idx, q) DESC) AS rank
    FROM documentos, plainto_tsquery('spanish', :query_text) q
    WHERE search_idx @@ q
    ORDER BY ts_rank_cd(search_idx, q) DESC
    LIMIT 40
)
SELECT COALESCE(s.id, l.id) AS id,
       COALESCE(1.0 / (60 + s.rank), 0.0) + COALESCE(1.0 / (60 + l.rank), 0.0) AS rrf_score
FROM semantic s
FULL OUTER JOIN lexical l USING (id)
ORDER BY rrf_score DESC
LIMIT 10;
```

***

## 3. Extensiones de Inteligencia Artificial: pgvector y Búsqueda Semántica

### 3.1 Por Qué pgvector (vs. Bases de Datos Vectoriales Dedicadas)

**Ventajas clave**: [databricks](https://www.databricks.com/blog/what-is-pgvector)
- **Unificación**: Vectores + datos relacionales en una sola transacción ACID.
- **Sin sincronización**: No hay dual writes ni drift entre sistemas.
- **Filtrado nativo**: `WHERE` + ordenamiento vectorial en una sola consulta.
- **Costo operacional**: Una sola base de datos que mantener, monitorear y respaldar.

**Cuándo pgvector es suficiente**: [databricks](https://www.databricks.com/blog/what-is-pgvector)
- Hasta **~10-50M vectores** con latencias de un dígito en ms.
- Cargas de trabajo de **miles de QPS** en instancias bien dimensionadas.
- Equipos que ya operan PostgreSQL en producción.

**Cuándo migrar a VDB dedicado** (Pinecone, Qdrant, Weaviate):
- Más de 50M vectores con requisitos estrictos de recall/latencia.
- Decenas de miles de QPS con p99 < 10ms.
- Necesidad de features avanzadas (reranking cross-encoder, multi-vector, autoscaling gestionado).

### 3.2 Embeddings: Concepto y Dimensiones

Un **embedding** es un vector numérico de \(N\) dimensiones que mapea significado semántico. [databricks](https://www.databricks.com/blog/what-is-pgvector)

**Dimensiones comunes por modelo**: [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

| Modelo | Dimensiones |
|--------|-------------|
| OpenAI `text-embedding-3-small` | 1536 |
| OpenAI `text-embedding-3-large` | 3072 |
| Cohere `embed-v4.0` | 1536 (configurable) |
| `all-MiniLM-L6-v2` (local) | 384 |

**Regla crítica**: La dimensión del tipo `VECTOR(N)` debe coincidir exactamente con el modelo de embedding. [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

### 3.3 Instalación y Configuración

```sql
-- Habilitar extensión (una vez por base de datos)
CREATE EXTENSION IF NOT EXISTS vector;

-- Verificar versión (0.8.2+ recomendado por parches de seguridad CVE-2026-3172)
SELECT * FROM pg_extension WHERE extname = 'vector';
```

**Esquema de tabla**: [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```sql
CREATE TABLE documentos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fuente_id BIGINT REFERENCES fuentes(id),
    contenido TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding VECTOR(1536), -- Debe coincidir con el modelo
    creado_en TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.4 Operadores de Distancia

| Operador | Métrica | Uso Recomendado |
|----------|---------|-----------------|
| `<=>` | Distancia de coseno | **Default para texto**; magnitud no importa |
| `<->` | Distancia euclidiana (L2) | Vectores normalizados o distancia geométrica |
| `<#>` | Producto punto negativo | Embeddings ya normalizados L2 (más rápido) |
| `<+>` | Distancia L1 (Manhattan) | Raro; solo si el modelo fue entrenado para L1 |

**Nota**: `<=>` devuelve **distancia** (0 = idéntico, 2 = opuesto). Similitud de coseno = `1 - (a <=> b)`. [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

### 3.5 Indexación: HNSW vs. IVFFlat

**HNSW (Hierarchical Navigable Small World)**: [databricks](https://www.databricks.com/blog/what-is-pgvector)
- **Mejor rendimiento** en consultas (speed-recall tradeoff óptimo).
- Construcción más lenta, mayor uso de memoria.
- **Recomendado para producción** salvo restricciones de memoria/tiempo.

```sql
CREATE INDEX ON documentos
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Ajuste en tiempo de consulta
SET hnsw.ef_search = 100; -- Mayor recall, más latencia
```

**IVFFlat (Inverted File with Flat compression)**: [databricks](https://www.databricks.com/blog/what-is-pgvector)
- Construcción más rápida, menor memoria.
- Requiere datos presentes antes de crear índice (entrenamiento de particiones).
- Menor recall que HNSW.

```sql
-- Cargar datos primero, luego crear índice
CREATE INDEX ON documentos
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000); -- ~rows/1000 hasta 1M, ~sqrt(rows) después

SET ivfflat.probes = 10; -- Controla recall en consulta
```

### 3.6 Filtrado Combinado (WHERE + Vector)

**Problema histórico**: En versiones < 0.8, combinar `WHERE` + ANN podía descartar demasiados resultados (overfiltering).

**Solución en pgvector 0.8+**: **Iterative index scans**: [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```sql
SET hnsw.iterative_scan = strict_order; -- O relaxed_order para más velocidad
```

**Ejemplo de producción (RAG con filtros de tenant)**: [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```sql
SELECT d.contenido, d.metadata, 1 - (d.embedding <=> %s) AS similitud
FROM documentos d
JOIN fuentes f ON f.id = d.fuente_id
WHERE f.tenant_id = %s
  AND f.publicado = true
ORDER BY d.embedding <=> %s
LIMIT 5;
```

### 3.7 Pipeline RAG Completo con pgvector

**Ingesta** (chunking + embedding + almacenamiento): [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```python
from openai import OpenAI
import psycopg
from pgvector.psycopg import register_vector

client = OpenAI()
conn = psycopg.connect("postgresql://localhost/app")
register_vector(conn)

EMBED_MODEL = "text-embedding-3-small"

def embed(text: str) -> list[float]:
    resp = client.embeddings.create(model=EMBED_MODEL, input=text)
    return resp.data[0].embedding

def ingestar(fuente_id: int, chunks: list[str]) -> None:
    with conn.cursor() as cur:
        for chunk in chunks:
            cur.execute("""
                INSERT INTO documentos (fuente_id, contenido, embedding, metadata)
                VALUES (%s, %s, %s, %s)
            """, (fuente_id, chunk, embed(chunk), {"modelo": EMBED_MODEL}))
    conn.commit()
```

**Tips de ingeniería**: [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)
- **Chunking**: 300-600 tokens con 10-15% de overlap mejora recuperación.
- **Metadata**: Almacenar el modelo de embedding para saber qué rows re-embedear al cambiar de modelo.
- **Batch inserts**: Usar `COPY` o inserciones masivas para carga inicial.

**Recuperación** (búsqueda semántica + filtros): [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```python
def recuperar(consulta: str, tenant_id: int, k: int = 5) -> list[dict]:
    query_vec = embed(consulta)
    with conn.cursor() as cur:
        cur.execute("SET hnsw.iterative_scan = strict_order")
        cur.execute("""
            SELECT d.contenido, d.metadata, 1 - (d.embedding <=> %s) AS similitud
            FROM documentos d
            JOIN fuentes f ON f.id = d.fuente_id
            WHERE f.tenant_id = %s AND f.publicado
            ORDER BY d.embedding <=> %s
            LIMIT %s
        """, (query_vec, tenant_id, query_vec, k))
        cols = [c.name for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]
```

**Generación** (augment + LLM): [maddevs](https://maddevs.io/writeups/pgvector-postgresql-relational-data-ai-embeddings/)

```python
def responder(consulta: str, tenant_id: int) -> str:
    contexto_rows = recuperar(consulta, tenant_id)
    contexto = "\n\n---\n\n".join(r["contenido"] for r in contexto_rows)
    
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "Responde solo con el contexto proporcionado."},
            {"role": "user", "content": f"Contexto:\n{contexto}\n\nPregunta: {consulta}"}
        ]
    )
    return resp.choices[0].message.content
```

### 3.8 Optimización de Producción

**Configuración recomendada**: [zenvanriel](https://zenvanriel.com/ai-engineer-blog/pgvector-production-guide/)
- **work_mem**: Aumentar para operaciones vectoriales (ej. `4GB` en instancias grandes).
- **maintenance_work_mem**: Crítico para builds de índices rápidos.
- **Parallel query**: Habilitar para mejor throughput (`max_parallel_workers_per_gather`).
- **Connection pooling**: Usar `pgbouncer` (vector queries pueden mantener conexiones más tiempo).

**Mantenimiento**: [zenvanriel](https://zenvanriel.com/ai-engineer-blog/pgvector-production-guide/)
- **EXPLAIN ANALYZE**: Verificar que usa índice (no sequential scan).
- **Monitoreo de storage**: Vectores consumen espacio significativo (1536 dims × 4 bytes ≈ 6KB por vector).
- **Rebuild de índices**: Programar en ventanas de mantenimiento si hay degradación.

***

## 4. Administración de Usuarios, Roles y Permisos (RBAC)

### 4.1 Principio de Menor Privilegio

El modelo RBAC organiza permisos en **roles (contenedores)** que se asignan a **usuarios (identidades)**. [zenvanriel](https://zenvanriel.com/ai-engineer-blog/pgvector-production-guide/)

**Patrón empresarial**: [zenvanriel](https://zenvanriel.com/ai-engineer-blog/pgvector-production-guide/)

```sql
-- 1. Crear rol de grupo (sin login)
CREATE ROLE analista_datos_gr NOLOGIN;

-- 2. Asignar permisos al rol (esquema + tablas)
GRANT USAGE ON SCHEMA public TO analista_datos_gr;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista_datos_gr;

-- 3. Crear usuario y otorgar rol
CREATE USER analista_junior_01 WITH PASSWORD 'ClaveSegura2026';
GRANT analista_datos_gr TO analista_junior_01;

-- 4. Aplicar menor privilegio (revocar peligroso)
REVOKE DELETE ON TABLE ventas FROM analista_datos_gr;
REVOKE CREATE ON SCHEMA public FROM analista_datos_gr;
```

### 4.2 Row-Level Security (RLS) para Multi-Tenant

En arquitecturas SaaS, RLS garantiza aislamiento de datos por tenant a nivel de base de datos. [zenvanriel](https://zenvanriel.com/ai-engineer-blog/pgvector-production-guide/)

```sql
-- Habilitar RLS en tabla
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

-- Crear política por tenant
CREATE POLICY tenant_isolation ON documentos
    USING (tenant_id = current_setting('app.current_tenant')::INTEGER);

-- En la aplicación, establecer contexto por conexión
SET app.current_tenant = '42';
```

**Ventaja**: Una sola base de datos, múltiples tenants aislados sin duplicar infraestructura.

### 4.3 Auditoría y Logging de Accesos

**Mejor práctica**: Habilitar `log_statement` y `log_duration` para consultas sensibles.

```sql
-- En postgresql.conf
log_statement = 'mod'  -- log solo DDL + DML
log_duration = on
log_min_duration_statement = 1000  -- log queries > 1s
```

***

## 5. Mantenimiento Físico del Motor: MVCC y VACUUM

### 5.1 MVCC y Tuplas Muertas (Bloat)

PostgreSQL usa **MVCC (Multi-Version Concurrency Control)** para permitir lecturas y escrituras simultáneas sin bloqueos. [stackharbor](https://stackharbor.com/en/knowledge-base/pg-full-text-search-tsvector/)

**Mecanismo**:
- `UPDATE`/`DELETE` no sobrescribe filas: crea nuevas versiones o marca antiguas como obsoletas ("tuplas muertas").
- Acumulación excesiva → **bloat** (hinchazón) en tablas e índices → degradación de rendimiento.

### 5.2 VACUUM y VACUUM ANALYZE

**Comandos clave**: [stackharbor](https://stackharbor.com/en/knowledge-base/pg-full-text-search-tsvector/)
- `VACUUM`: Recupera espacio de tuplas muertas para reutilización.
- `VACUUM ANALYZE`: Limpia espacio + actualiza estadísticas para el optimizador de consultas.

**Mejor práctica**: Ejecutar manualmente tras cargas masivas de datos, aunque `autovacuum` esté activo.

```sql
-- Después de carga masiva
VACUUM ANALYZE pedidos_modernos;
VACUUM ANALYZE documentos;
```

**Tuning de autovacuum** (en `postgresql.conf`):

```conf
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 60s
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_scale_factor = 0.05
```

**Monitoreo de bloat**: [stackharbor](https://stackharbor.com/en/knowledge-base/pg-full-text-search-tsvector/)

```sql
SELECT 
    schemaname, 
    relname, 
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

***

## Checklist de Producción para Data Engineers

| Área | Acción | Prioridad |
|------|--------|-----------|
| **JSONB** | Usar siempre JSONB (no JSON) + índice GIN en campos consultados | Alta |
| **FTS** | Columna generada `tsvector` + GIN index; evitar `to_tsvector()` en query time | Alta |
| **pgvector** | HNSW index para producción; `hnsw.iterative_scan` para filtros combinados | Alta |
| **RAG** | Chunking 300-600 tokens con overlap; metadata con modelo de embedding | Media |
| **RBAC** | Roles NOLOGIN + usuarios LOGIN; aplicar RLS para multi-tenant | Alta |
| **Mantenimiento** | `VACUUM ANALYZE` post-carga masiva; monitorear bloat trimestralmente | Media |

