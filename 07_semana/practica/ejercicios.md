# Semana 7 — Ejercicios: PostgreSQL Moderno (JSONB y Extensiones AI)

Este set de ejercicios acompaña al script `semana7_setup.sql`. Antes de empezar, cargá el entorno:

```bash
createdb curso_pg_moderno
psql -d curso_pg_moderno -f semana7_setup.sql
```

Cada ejercicio sigue el mismo formato: **Consigna** → **Resolución paso a paso** → **Tips**.

---

## Bloque 1 — Datos semi-estructurados con JSONB

### Ejercicio 1.1 — Extraer y filtrar por campos anidados

**Consigna:** Listá el nombre y el email de todos los usuarios cuyo tema (`theme`) configurado sea `"dark"`, junto con si tienen las notificaciones push activadas.

**Resolución:**

```sql
SELECT
    nombre,
    email,
    perfil -> 'settings' ->> 'theme' AS tema,
    (perfil -> 'settings' -> 'notificaciones' ->> 'push')::boolean AS push_activo
FROM usuarios
WHERE perfil -> 'settings' ->> 'theme' = 'dark';
```

**Paso a paso:**
1. `perfil -> 'settings'` navega al objeto `settings` y devuelve `jsonb` (necesitamos seguir bajando).
2. `-> 'notificaciones'` vuelve a bajar un nivel, todavía como `jsonb`.
3. `->> 'push'` en el último salto convierte el valor final a `text`; como sabemos que es booleano, lo casteamos con `::boolean` para poder usarlo como tal en la aplicación.
4. En el `WHERE` usamos `->>` directamente porque necesitamos comparar contra un `text` literal (`'dark'`).

**Tips:**
- Usá `->` mientras sigas navegando dentro del JSON y `->>` solo en el último paso, cuando necesites el valor final como texto.
- Si vas a filtrar seguido por esta ruta, es candidata a un índice de expresión (ver Ejercicio 1.3).

---

### Ejercicio 1.2 — Búsqueda con `@>` y aprovechamiento del índice GIN

**Consigna:** Encontrá todos los pedidos enviados por método `"Express"` que además sean frágiles, usando el operador de contención para que la consulta pueda usar el índice GIN ya creado sobre `detalles_envio`.

**Resolución:**

```sql
EXPLAIN ANALYZE
SELECT id, usuario_id, detalles_envio ->> 'metodo' AS metodo_envio
FROM pedidos_modernos
WHERE detalles_envio @> '{"metodo": "Express", "es_fragil": true}';
```

**Paso a paso:**
1. `@>` pregunta "¿el JSONB de la columna *contiene* esta estructura?" — es una comparación estructural, no textual.
2. Como `detalles_envio` tiene un índice `GIN`, Postgres puede resolver `@>` sin recorrer toda la tabla.
3. `EXPLAIN ANALYZE` te deja confirmar en el plan de ejecución si aparece `Bitmap Index Scan on idx_pedidos_detalles_gin` (índice usado) en vez de `Seq Scan` (recorrido completo).

**Tips:**
- `@>` es el operador que mejor aprovecha el índice GIN por defecto (`jsonb_ops`). Operadores como `->>` en el `WHERE` normalmente **no** usan ese índice a menos que crees uno de expresión específico.
- Si tus consultas más frecuentes son de igualdad exacta sobre pocas claves, `@>` + GIN es la combinación más simple y efectiva.

---

### Ejercicio 1.3 — Índice de expresión para una ruta específica

**Consigna:** Vas a filtrar usuarios por `theme` con mucha frecuencia. Creá un índice de expresión que acelere específicamente esa consulta y comprobá que se usa.

**Resolución:**

```sql
CREATE INDEX idx_usuarios_theme ON usuarios ((perfil -> 'settings' ->> 'theme'));

EXPLAIN ANALYZE
SELECT nombre, email
FROM usuarios
WHERE perfil -> 'settings' ->> 'theme' = 'dark';
```

**Paso a paso:**
1. Un índice de expresión indexa el *resultado* de una expresión (acá, el texto extraído de la ruta), no la columna completa.
2. La expresión en el `CREATE INDEX` debe coincidir **exactamente** (mismos operadores, mismo casteo) con la que usás en el `WHERE`, o Postgres no lo va a poder emparejar.
3. Con datos reales de volumen, `EXPLAIN ANALYZE` debería mostrar `Index Scan using idx_usuarios_theme` en vez de recorrer toda la tabla.

**Tips:**
- Los índices de expresión son ideales cuando siempre consultás la *misma* ruta puntual dentro del JSON, en vez de contenciones genéricas tipo `@>`.
- No abuses de esto: cada índice de expresión que agregás cuesta en escritura. Reservalo para rutas realmente calientes.

---

### Ejercicio 1.4 — Actualizar un campo anidado sin reescribir todo el documento

**Consigna:** Activá la notificación por email para el usuario `martin@example.com`, modificando solo esa clave dentro del JSONB.

**Resolución:**

```sql
UPDATE usuarios
SET perfil = jsonb_set(perfil, '{settings,notificaciones,email}', 'true', true)
WHERE email = 'martin@example.com';
```

**Paso a paso:**
1. `jsonb_set(target, path, new_value, create_missing)` recibe la ruta como array de texto (`'{settings,notificaciones,email}'`).
2. `new_value` debe ser un valor `jsonb` válido — por eso `'true'` (con comillas) y no `true` a secas.
3. El cuarto argumento (`true`) le dice a Postgres que cree la clave si no existiera; ponelo en `false` si querés que falle silenciosamente (no la cree) cuando la ruta no exista.

**Tips:**
- `jsonb_set` es la forma correcta de hacer updates parciales; evitá reconstruir el objeto completo en la aplicación y volver a insertarlo entero, porque perdés atomicidad y es más caro en tráfico.
- Para *eliminar* una clave existe el operador `#-`, por ejemplo: `perfil #- '{settings,notificaciones}'`.

---

## Bloque 2 — Full-Text Search (FTS)

### Ejercicio 2.1 — De `LIKE` a `to_tsvector`/`to_tsquery`

**Consigna:** Buscá artículos que hablen de "pollo" usando primero `LIKE` y después FTS. Compará los resultados y notá la diferencia cuando el texto dice "pollos" (plural) o "asado" (sinónimo funcional).

**Resolución:**

```sql
-- Versión LIKE (no detecta variantes lingüísticas)
SELECT titulo FROM articulos WHERE contenido ILIKE '%pollo%';

-- Versión FTS (detecta variantes por stemming, aunque no sinónimos)
SELECT titulo
FROM articulos
WHERE to_tsvector('spanish', contenido) @@ to_tsquery('spanish', 'pollo');
```

**Paso a paso:**
1. `ILIKE '%pollo%'` funciona, pero es un escaneo de texto plano: no sabe que "pollo" y "pollos" son la misma raíz, y tampoco puede rankear resultados.
2. `to_tsvector('spanish', contenido)` tokeniza y reduce cada palabra a su raíz (stemming) usando el diccionario en español.
3. `to_tsquery('spanish', 'pollo')` aplica el mismo proceso a la búsqueda, así "pollo" matchea tanto "pollo" como "pollos" o "pollos" conjugados.
4. `@@` es el operador de coincidencia entre un `tsvector` y un `tsquery`.

**Tips:**
- FTS entiende morfología (plurales, conjugaciones) pero no sinónimos reales — "pollo" y "ave" no van a matchear salvo que definas un diccionario de sinónimos custom.
- Especificar siempre el idioma (`'spanish'`) es obligatorio para que el stemming sea correcto; con el diccionario en inglés, "corriendo" no se reduce a nada útil.

---

### Ejercicio 2.2 — Consultas compuestas con operadores lógicos

**Consigna:** Encontrá artículos que mencionen "pollo" pero que **no** sean recetas (es decir, que no contengan la palabra "receta").

**Resolución:**

```sql
SELECT titulo
FROM articulos
WHERE search_idx @@ to_tsquery('spanish', 'pollo & !receta');
```

**Paso a paso:**
1. Usamos `search_idx`, la columna generada (`STORED`) que ya tiene el `tsvector` precalculado — así evitamos recalcular `to_tsvector` en cada fila de la consulta.
2. `&` exige que ambos lados sean verdaderos; `!` niega el término siguiente.
3. El resultado esperado es el artículo de "Pollo a la parrilla con hierbas" quedando afuera si tiene la palabra "receta" en su contenido, y "Recetas de pollo al horno" quedando afuera por contener "receta" explícitamente.

**Tips:**
- Siempre que definas una columna generada tipo `search_idx`, usala en el `WHERE` en vez de recalcular `to_tsvector()` al vuelo — es la diferencia entre usar el índice GIN directamente o no.
- El operador `<->` (FOLLOWED BY) es útil para frases exactas, por ejemplo `to_tsquery('spanish', 'pollo <-> horno')` buscaría "pollo" seguido inmediatamente de "horno".

---

### Ejercicio 2.3 — Ranking de relevancia con `ts_rank`

**Consigna:** Buscá artículos relacionados con "índices" y "rendimiento", ordenados por relevancia (no por fecha).

**Resolución:**

```sql
SELECT
    titulo,
    ts_rank(search_idx, to_tsquery('spanish', 'indice | rendimiento')) AS relevancia
FROM articulos
WHERE search_idx @@ to_tsquery('spanish', 'indice | rendimiento')
ORDER BY relevancia DESC
LIMIT 5;
```

**Paso a paso:**
1. `|` (OR) trae artículos que mencionen cualquiera de los dos términos, ampliando el recall.
2. `ts_rank()` calcula un score en base a la frecuencia de aparición de los términos de búsqueda en el documento (no considera posición).
3. Ordenar por `relevancia DESC` prioriza los artículos donde esos términos son más centrales al contenido, no simplemente los más recientes.

**Tips:**
- Si además de frecuencia te importa que los términos aparezcan *cerca* uno del otro, usá `ts_rank_cd()` (cover density) en vez de `ts_rank()`.
- El ranking por sí solo no reemplaza un buen filtro: combiná `@@` para filtrar y `ts_rank` solo para ordenar, nunca al revés (sería más caro).

---

### Ejercicio 2.4 — Diagnosticar y arreglar un FTS lento

**Consigna:** Alguien escribió esta consulta y se queja de que es lenta en una tabla de 500.000 artículos. Encontrá el problema y arreglalo.

```sql
-- Consulta original (lenta)
SELECT titulo FROM articulos
WHERE to_tsvector('spanish', contenido) @@ to_tsquery('spanish', 'postgres');
```

**Resolución:**

```sql
EXPLAIN ANALYZE
SELECT titulo FROM articulos
WHERE to_tsvector('spanish', contenido) @@ to_tsquery('spanish', 'postgres');
-- Plan esperado: Seq Scan (recalcula to_tsvector() fila por fila, ignora el índice GIN)

-- Arreglo: usar la columna generada que ya está indexada
EXPLAIN ANALYZE
SELECT titulo FROM articulos
WHERE search_idx @@ to_tsquery('spanish', 'postgres');
-- Plan esperado: Bitmap Index Scan on idx_fts_articulos
```

**Paso a paso:**
1. El índice GIN (`idx_fts_articulos`) está creado sobre la columna `search_idx`, no sobre la *expresión* `to_tsvector('spanish', contenido)` calculada al vuelo.
2. Aunque el resultado final sea el mismo texto, Postgres no relaciona automáticamente una llamada a función en el `WHERE` con un índice sobre otra columna, salvo que sean sintácticamente la misma expresión indexada.
3. Cambiando el `WHERE` para que apunte a `search_idx` (la columna ya materializada), la consulta puede usar el índice.

**Tips:**
- Esta es la causa más común de "mi FTS no usa el índice": comparar contra `to_tsvector(...)` calculado en la consulta en vez de contra la columna/índice ya generados.
- Regla general: siempre corré `EXPLAIN ANALYZE` antes de asumir que un índice se está usando.

---

## Bloque 3 — pgvector y búsqueda semántica

> **Nota:** con el `semana7_setup.sql` actualizado, `documentos.embedding` queda en
> `NULL` (columna `VECTOR(768)`) hasta que corrés `embeddings/load_embeddings.py`,
> que carga vectores **reales** generados con `gemini-embedding-001`. Los ejercicios
> 3.1 a 3.4 de abajo usan vectores de consulta *aleatorios* solo para practicar la
> sintaxis de pgvector sin depender de ninguna API — podés resolverlos igual sin
> haber corrido el loader. Para ver un caso de similitud semántica con significado
> real, corré `uv run search_documentos.py "tu consulta"` desde la carpeta
> `embeddings/` después de cargar los embeddings.

### Ejercicio 3.1 — Búsqueda por similitud (kNN) básica

**Consigna:** Dado un vector de consulta arbitrario, encontrá los 3 documentos más similares (por coseno) dentro del tenant 1.

**Resolución:**

```sql
WITH query_vec AS (
    SELECT (SELECT ('[' || string_agg(round(random()::numeric, 4)::text, ',') || ']')
            FROM generate_series(1, 768))::vector AS v
)
SELECT
    d.contenido,
    f.nombre AS fuente,
    1 - (d.embedding <=> q.v) AS similitud
FROM documentos d
JOIN fuentes f ON f.id = d.fuente_id
CROSS JOIN query_vec q
WHERE f.tenant_id = 1
ORDER BY d.embedding <=> q.v
LIMIT 3;
```

**Paso a paso:**
1. `query_vec` simula el embedding que en producción vendría de tu modelo (OpenAI, MiniLM, etc.) — en la práctica lo generás en tu aplicación y lo pasás como parámetro.
2. `<=>` calcula **distancia** de coseno: cuanto más chica, más parecidos. Por eso ordenamos `ORDER BY d.embedding <=> q.v` ascendente (los más cercanos primero).
3. `1 - (d.embedding <=> q.v)` convierte esa distancia en un score de "similitud" más intuitivo para mostrar (cerca de 1 = muy similar).
4. El filtro `f.tenant_id = 1` restringe la búsqueda semántica a un solo cliente/tenant.

**Tips:**
- No confundas distancia y similitud: `<=>` devuelve distancia (0 = idéntico), así que ordená siempre ascendente cuando busques "los más parecidos".
- Con vectores aleatorios como los de este dataset de práctica, la similitud no tiene significado semántico real — el objetivo del ejercicio es la sintaxis, no los resultados.

---

### Ejercicio 3.2 — Elegir el operador de distancia correcto

**Consigna:** Explicá (con una consulta de ejemplo cada uno) cuándo usarías `<=>`, `<->` y `<#>`, y calculá los tres para el mismo par de vectores para ver que dan resultados distintos.

**Resolución:**

```sql
SELECT
    d1.id AS doc_a,
    d2.id AS doc_b,
    d1.embedding <=> d2.embedding AS distancia_coseno,
    d1.embedding <-> d2.embedding AS distancia_euclidiana,
    d1.embedding <#> d2.embedding AS producto_punto_negativo
FROM documentos d1, documentos d2
WHERE d1.id = 1 AND d2.id = 2;
```

**Paso a paso:**
1. `<=>` (coseno): ideal para texto/embeddings semánticos donde solo importa la *dirección* del vector, no su magnitud — es el default recomendado para búsquedas de significado.
2. `<->` (euclidiana/L2): tiene sentido cuando la magnitud del vector importa (por ejemplo, vectores ya normalizados o datos geométricos reales, no solo semánticos).
3. `<#>` (producto punto negativo): más rápido de calcular que el coseno, pero solo es válido si tus embeddings ya vienen normalizados L2 de antemano (si no, el resultado no es comparable entre vectores).

**Tips:**
- El operador de distancia usado en la consulta debe coincidir con las `_ops` del índice (`vector_cosine_ops`, `vector_l2_ops`, `vector_ip_ops`) o el índice no se va a usar.
- Ante la duda con embeddings de modelos de lenguaje modernos (OpenAI, Cohere, MiniLM), `<=>` (coseno) es la opción segura por defecto.

---

### Ejercicio 3.3 — HNSW vs IVFFlat: crear y comparar

**Consigna:** Creá un índice IVFFlat alternativo sobre `documentos.embedding` y compará (conceptualmente) cuándo usarías cada uno.

**Resolución:**

```sql
-- HNSW ya existe en el setup; agregamos IVFFlat como alternativa
CREATE INDEX documentos_embedding_ivfflat
ON documentos USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 10);  -- con pocos documentos de práctica, 'lists' bajo alcanza

SET ivfflat.probes = 5;

EXPLAIN ANALYZE
SELECT id FROM documentos
ORDER BY embedding <=> (SELECT embedding FROM documentos LIMIT 1)
LIMIT 5;
```

**Paso a paso:**
1. A diferencia de HNSW, IVFFlat necesita datos *ya cargados* antes de crear el índice, porque arma particiones (`lists`) basadas en la distribución real de los vectores.
2. `lists` controla cuántas particiones se crean; como regla general, `filas/1000` hasta 1M de filas, y `sqrt(filas)` en tablas más grandes.
3. `ivfflat.probes` controla cuántas particiones revisa la consulta: más probes = más recall pero más lento.
4. En este dataset chico de práctica la diferencia de performance no se va a notar; el ejercicio es familiarizarse con la sintaxis y los trade-offs.

**Tips:**
- HNSW: mejor recall/latencia en consulta, pero construcción más lenta y más memoria — es la opción por defecto recomendada para producción salvo restricciones de recursos.
- IVFFlat: construcción más rápida y liviana, pero hay que re-entrenar (recrear) el índice si la distribución de los datos cambia mucho con el tiempo.

---

### Ejercicio 3.4 — Búsqueda híbrida: FTS + vectorial (RRF)

**Consigna:** Combiná la búsqueda léxica (FTS) sobre `articulos` con una búsqueda semántica ficticia, fusionando el ranking con Reciprocal Rank Fusion (RRF), tal como se usa en pipelines RAG.

**Resolución:**

```sql
WITH query_vec AS (
    SELECT (SELECT ('[' || string_agg(round(random()::numeric, 4)::text, ',') || ']')
            FROM generate_series(1, 768))::vector AS v
),
semantic AS (
    SELECT d.id, ROW_NUMBER() OVER (ORDER BY d.embedding <=> q.v) AS rank
    FROM documentos d, query_vec q
    ORDER BY d.embedding <=> q.v
    LIMIT 20
),
lexical AS (
    SELECT a.id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(a.search_idx, tq) DESC) AS rank
    FROM articulos a, to_tsquery('spanish', 'postgres | indice') tq
    WHERE a.search_idx @@ tq
    ORDER BY ts_rank_cd(a.search_idx, tq) DESC
    LIMIT 20
)
SELECT
    COALESCE(s.id, l.id) AS id,
    COALESCE(1.0 / (60 + s.rank), 0.0) + COALESCE(1.0 / (60 + l.rank), 0.0) AS rrf_score
FROM semantic s
FULL OUTER JOIN lexical l USING (id)
ORDER BY rrf_score DESC
LIMIT 10;
```

**Paso a paso:**
1. Ejecutamos las dos búsquedas por separado (semántica y léxica), cada una limitada a un top-N (acá 20) y con su propio `ROW_NUMBER()` de ranking interno.
2. La fórmula RRF (`1 / (k + rank)`, con `k = 60` como constante estándar de la literatura) evita que una sola búsqueda domine el score solo por tener valores numéricos más grandes — normaliza por *posición*, no por score crudo.
3. El `FULL OUTER JOIN` combina ambos rankings: un documento que aparece en ambas listas suma los dos términos; uno que solo aparece en una lista usa `COALESCE(..., 0.0)` para el lado ausente.
4. Nota: en este ejercicio `documentos` y `articulos` son tablas distintas del dataset de práctica — en un caso real ambos rankings deberían apuntar al mismo conjunto de ítems (mismo `id`).

**Tips:**
- RRF es popular porque es simple y no requiere calibrar pesos entre scores de naturaleza distinta (distancia vectorial vs. `ts_rank`).
- En producción, esta fusión normalmente se hace sobre la *misma* tabla de documentos que tiene tanto `tsvector` como `embedding`, no sobre tablas separadas como en este ejercicio simplificado.

---

## Bloque 4 — Roles, permisos y Row-Level Security

### Ejercicio 4.1 — RBAC de menor privilegio

**Consigna:** Creá un rol de solo lectura para un equipo de analistas, que pueda hacer `SELECT` en todas las tablas pero explícitamente no pueda borrar filas de `ventas` ni crear nuevos objetos.

**Resolución:**

```sql
CREATE ROLE analista_datos_gr NOLOGIN;
GRANT USAGE ON SCHEMA public TO analista_datos_gr;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista_datos_gr;

CREATE USER analista_junior_01 WITH PASSWORD 'CambiarEnProduccion2026';
GRANT analista_datos_gr TO analista_junior_01;

REVOKE DELETE ON TABLE ventas FROM analista_datos_gr;
REVOKE CREATE ON SCHEMA public FROM analista_datos_gr;
```

**Paso a paso:**
1. Creamos primero un **rol de grupo** (`NOLOGIN`) que actúa como contenedor de permisos, en vez de otorgar permisos directamente a cada persona.
2. `GRANT SELECT ... ALL TABLES IN SCHEMA public` habilita lectura en todo el schema de una sola vez.
3. El usuario real (`analista_junior_01`, con `LOGIN` implícito por tener password) hereda los permisos al recibir el rol vía `GRANT analista_datos_gr TO ...`.
4. Los `REVOKE` son defensivos: aunque `SELECT` no incluye `DELETE` ni `CREATE`, dejarlos explícitos documenta la intención y protege ante futuros `GRANT ALL` accidentales.

**Tips:**
- Asignar permisos a roles de grupo (no a usuarios individuales) es lo que hace mantenible el RBAC cuando el equipo crece: das de alta/baja gente sin tocar permisos.
- `ALL TABLES IN SCHEMA public` solo afecta tablas que **ya existen** al momento del GRANT — para que las tablas nuevas hereden el permiso automáticamente, necesitás `ALTER DEFAULT PRIVILEGES`.

---

### Ejercicio 4.2 — Row-Level Security multi-tenant

**Consigna:** Sobre la tabla `documentos`, activá RLS para que cada conexión solo pueda ver los documentos del tenant configurado en la sesión.

**Resolución:**

```sql
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON documentos
    USING (
        fuente_id IN (
            SELECT id FROM fuentes WHERE tenant_id = current_setting('app.current_tenant')::INTEGER
        )
    );

-- Simular una sesión del tenant 1
SET app.current_tenant = '1';
SELECT count(*) FROM documentos;   -- solo ve documentos de fuentes con tenant_id = 1

-- Simular una sesión del tenant 2
SET app.current_tenant = '2';
SELECT count(*) FROM documentos;   -- solo ve documentos de fuentes con tenant_id = 2
```

**Paso a paso:**
1. `ENABLE ROW LEVEL SECURITY` no filtra nada por sí solo — solo prepara la tabla para que las políticas (`POLICY`) definan qué filas son visibles.
2. La política usa `current_setting('app.current_tenant')`, una variable de sesión que la aplicación setea al abrir la conexión (típicamente después de autenticar al usuario).
3. Como `documentos` no tiene `tenant_id` directo, la política resuelve el tenant indirectamente a través de `fuente_id -> fuentes.tenant_id`.
4. Cambiar `app.current_tenant` entre consultas simula lo que pasaría con dos conexiones distintas, cada una atada a un tenant.

**Tips:**
- RLS es una capa de defensa adicional, no un reemplazo de filtrar por `tenant_id` en tu aplicación — protege incluso si alguien olvida el `WHERE` en una query.
- Ojo: por defecto, el dueño de la tabla (o un rol con `BYPASSRLS`) **no** está sujeto a las políticas. Si vas a probar RLS, conectate con un rol sin superusuario.

---

### Ejercicio 4.3 — Auditar quién puede hacer qué

**Consigna:** Sin usar herramientas externas, escribí una consulta sobre el catálogo de Postgres que liste todos los privilegios de tabla otorgados al rol `analista_datos_gr`.

**Resolución:**

```sql
SELECT
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista_datos_gr'
ORDER BY table_name, privilege_type;
```

**Paso a paso:**
1. `information_schema.role_table_grants` es una vista estándar (ANSI SQL) que expone permisos de tabla otorgados a roles, sin necesitar acceso a catálogos internos de Postgres.
2. Filtramos por `grantee` para ver específicamente qué puede hacer nuestro rol de analistas.
3. El resultado debería mostrar `SELECT` en todas las tablas, y *no* debería aparecer `DELETE` en `ventas` (por el `REVOKE` del ejercicio 4.1) ni `CREATE` en el schema (eso vive en otra vista, `information_schema.role_usage_grants`, ya que `CREATE` es a nivel schema, no tabla).

**Tips:**
- Para auditorías más completas conviene revisar también `pg_catalog.pg_roles` (atributos como `rolsuper`, `rolcreatedb`) y no solo permisos a nivel tabla.
- Automatizar esta consulta como parte de un pipeline de auditoría trimestral es una buena práctica antes de cada revisión de seguridad.

---

## Cómo seguir practicando

- Repetí los ejercicios del Bloque 3 conectando embeddings reales (por ejemplo con `sentence-transformers/all-MiniLM-L6-v2` en local, o la API de OpenAI) en vez de los vectores aleatorios del dataset de práctica — ahí vas a poder validar que la similitud semántica tiene sentido real.
- Corré `EXPLAIN ANALYZE` en cada consulta de este documento y confirmá qué tipo de scan usa cada una (`Seq Scan`, `Bitmap Index Scan`, `Index Scan`) — es el hábito más importante para escribir SQL de producción.
- Combiná los Bloques 1 y 4: agregá una política RLS sobre `pedidos_modernos` que filtre usando un campo dentro del propio JSONB (`detalles_envio ->> 'direccion' ->> 'ciudad'`, por ejemplo).