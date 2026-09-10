 -- ============================================================
 -- Semana 7: PostgreSQL Moderno (JSONB y Extensiones AI)
 -- Script de entorno: extensiones, schema, datos de ejemplo
 -- ============================================================
 -- Uso:
 --   createdb curso_pg_moderno
 --   psql -d curso_pg_moderno -f semana7_setup.sql
 -- ============================================================
 
 -- 0. Extensiones

 CREATE DATABASE IF NOT EXISTS curso_pg_moderno;

 CREATE EXTENSION IF NOT EXISTS vector;
 CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- útil para algún ejercicio extra de FTS/similaridad
 
 -- --------------------------------------------------------
 -- 1. Tablas base (usuarios / ventas) — soporte para RBAC y JSONB
 -- --------------------------------------------------------
 DROP TABLE IF EXISTS ventas CASCADE;
 DROP TABLE IF EXISTS pedidos_modernos CASCADE;
 DROP TABLE IF EXISTS usuarios CASCADE;
 
 CREATE TABLE usuarios (
     id           SERIAL PRIMARY KEY,
     nombre       TEXT NOT NULL,
     email        TEXT NOT NULL UNIQUE,
     perfil       JSONB NOT NULL DEFAULT '{}'   -- preferencias, tema, notificaciones
 );
 
 CREATE TABLE ventas (
     id           SERIAL PRIMARY KEY,
     usuario_id   INTEGER REFERENCES usuarios(id),
     monto        NUMERIC(10,2) NOT NULL,
     fecha        DATE NOT NULL DEFAULT CURRENT_DATE
 );
 
 -- --------------------------------------------------------
 -- 2. JSONB: pedidos con atributos dinámicos
 -- --------------------------------------------------------
 CREATE TABLE pedidos_modernos (
     id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     usuario_id       INTEGER NOT NULL REFERENCES usuarios(id),
     fecha_pedido     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     estado           TEXT NOT NULL CHECK (estado IN ('pendiente', 'enviado', 'entregado')),
     detalles_envio   JSONB NOT NULL DEFAULT '{}',
     metadata_api     JSONB DEFAULT '{}'
 );
 
 -- gen_random_uuid() vive en pgcrypto en versiones viejas; en PG 13+ está en core.
 CREATE EXTENSION IF NOT EXISTS pgcrypto;
 
 CREATE INDEX idx_pedidos_detalles_gin ON pedidos_modernos USING GIN (detalles_envio);
 
 -- --------------------------------------------------------
 -- 3. Full-Text Search: artículos
 -- --------------------------------------------------------
 DROP TABLE IF EXISTS articulos CASCADE;
 
 CREATE TABLE articulos (
     id                  SERIAL PRIMARY KEY,
     titulo              TEXT NOT NULL,
     contenido           TEXT NOT NULL,
     autor               TEXT,
     fecha_publicacion   DATE NOT NULL DEFAULT CURRENT_DATE,
     search_idx          TSVECTOR GENERATED ALWAYS AS (to_tsvector('spanish', titulo || ' ' || contenido)) STORED
 );
 
 CREATE INDEX idx_fts_articulos ON articulos USING GIN (search_idx);
 
 -- --------------------------------------------------------
 -- 4. pgvector: fuentes + documentos (para RAG y RLS multi-tenant)
 -- --------------------------------------------------------
 DROP TABLE IF EXISTS documentos CASCADE;
 DROP TABLE IF EXISTS fuentes CASCADE;
 
 CREATE TABLE fuentes (
     id          SERIAL PRIMARY KEY,
     nombre      TEXT NOT NULL,
     tenant_id   INTEGER NOT NULL,
     publicado   BOOLEAN NOT NULL DEFAULT TRUE
 );
 
 -- Usamos VECTOR(384) (dimensión de all-MiniLM-L6-v2) para mantener el script liviano.
 CREATE TABLE documentos (
     id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
     fuente_id    BIGINT REFERENCES fuentes(id),
     contenido    TEXT NOT NULL,
     metadata     JSONB DEFAULT '{}',
     embedding    VECTOR(384),
     creado_en    TIMESTAMPTZ DEFAULT NOW()
 );
 
 -- ============================================================
 -- POBLAR DATOS
 -- ============================================================
 
 -- --- usuarios ---
 INSERT INTO usuarios (nombre, email, perfil) VALUES
 ('Lucía Fernández', 'lucia@example.com', '{"settings": {"theme": "dark", "notificaciones": {"email": true, "push": false}}, "plan": "pro"}'),
 ('Martín Gómez',    'martin@example.com', '{"settings": {"theme": "light", "notificaciones": {"email": true, "push": true}}, "plan": "free"}'),
 ('Sofía Ramírez',   'sofia@example.com', '{"settings": {"theme": "dark", "notificaciones": {"email": false, "push": true}}, "plan": "enterprise"}'),
 ('Diego Torres',    'diego@example.com', '{"settings": {"theme": "light", "notificaciones": {"email": true, "push": false}}, "plan": "pro"}'),
 ('Valentina Suárez','valentina@example.com', '{"settings": {"theme": "dark", "notificaciones": {"email": true, "push": true}}, "plan": "free"}');
 
 -- --- ventas (para ejercicios de RBAC) ---
 INSERT INTO ventas (usuario_id, monto, fecha)
 SELECT (random() * 4 + 1)::INT, ROUND((random() * 5000 + 100)::NUMERIC, 2), CURRENT_DATE - (random() * 180)::INT
 FROM generate_series(1, 40);
 
 -- --- pedidos_modernos ---
 INSERT INTO pedidos_modernos (usuario_id, estado, detalles_envio, metadata_api) VALUES
 (1, 'enviado',   '{"metodo": "Express", "es_fragil": true,  "direccion": {"ciudad": "Buenos Aires", "cp": "1000"}}', '{"proveedor": "correo_argentino", "tracking": "AR123"}'),
 (2, 'pendiente', '{"metodo": "Standard", "es_fragil": false, "direccion": {"ciudad": "Córdoba", "cp": "5000"}}',      '{"proveedor": "oca", "tracking": null}'),
 (3, 'entregado', '{"metodo": "Express", "es_fragil": false, "direccion": {"ciudad": "Rosario", "cp": "2000"}}',      '{"proveedor": "andreani", "tracking": "AN987"}'),
 (1, 'entregado', '{"metodo": "Standard", "es_fragil": true,  "direccion": {"ciudad": "Mendoza", "cp": "5500"}}',    '{"proveedor": "correo_argentino", "tracking": "AR456"}'),
 (4, 'enviado',   '{"metodo": "Express", "es_fragil": true,  "direccion": {"ciudad": "La Plata", "cp": "1900"}}',   '{"proveedor": "oca", "tracking": "OC321"}'),
 (5, 'pendiente', '{"metodo": "Express", "es_fragil": false, "direccion": {"ciudad": "Salta", "cp": "4400"}}',      '{"proveedor": "andreani", "tracking": null}'),
 (2, 'entregado', '{"metodo": "Standard", "es_fragil": false, "direccion": {"ciudad": "Córdoba", "cp": "5000"}}',    '{"proveedor": "correo_argentino", "tracking": "AR789"}'),
 (3, 'enviado',   '{"metodo": "Express", "es_fragil": true,  "direccion": {"ciudad": "Rosario", "cp": "2000"}}',     '{"proveedor": "oca", "tracking": "OC654"}');
 
 -- --- artículos (para FTS) ---
 INSERT INTO articulos (titulo, contenido, autor, fecha_publicacion) VALUES
 ('Recetas de pollo al horno', 'Aprende a cocinar recetas fáciles de pollo al horno con papas y especias. El pollo asado es un clásico de la cocina argentina.', 'Ana López', '2026-01-10'),
 ('Guía de motores relacionales', 'PostgreSQL es un motor de bases de datos relacional avanzado, ampliamente usado por ingenieros de datos en producción.', 'Carlos Díaz', '2026-02-15'),
 ('Recetas veganas rápidas', 'Recetas rápidas y saludables sin ingredientes de origen animal, ideales para principiantes en la cocina vegana.', 'Ana López', '2026-03-02'),
 ('Optimización de consultas SQL', 'Los ingenieros de datos suelen optimizar consultas SQL corriendo EXPLAIN ANALYZE y ajustando índices para mejorar el rendimiento.', 'Carlos Díaz', '2026-03-20'),
 ('Pollo a la parrilla con hierbas', 'Una receta clásica: pollo a la parrilla marinado con hierbas frescas, ideal para un asado en familia.', 'Marcos Iglesias', '2026-04-05'),
 ('Introducción a los índices GIN', 'Los índices GIN aceleran búsquedas sobre columnas JSONB y de texto completo, siendo clave para el rendimiento en Postgres.', 'Carlos Díaz', '2026-04-18');
 
 -- --- fuentes (multi-tenant) ---
 INSERT INTO fuentes (nombre, tenant_id, publicado) VALUES
 ('Base de conocimiento - Tenant A', 1, TRUE),
 ('Manual interno - Tenant A',       1, TRUE),
 ('Documentación - Tenant B',        2, TRUE),
 ('Borradores - Tenant B',           2, FALSE);
 
 -- --- documentos con embeddings sintéticos (dim 384) ---
 -- En un caso real estos vectores saldrían de un modelo de embeddings (OpenAI, MiniLM, etc).
 -- Para practicar la sintaxis de pgvector generamos vectores aleatorios normalizados por texto.
 INSERT INTO documentos (fuente_id, contenido, metadata, embedding)
 SELECT
     f.id,
     d.contenido,
     jsonb_build_object('modelo', 'demo-random-384'),
     (SELECT ('[' || string_agg(round(random()::numeric, 4)::text, ',') || ']')
      FROM generate_series(1, 384))::vector
 FROM fuentes f
 JOIN LATERAL (
     VALUES
         ('Cómo resetear tu contraseña en el portal interno'),
         ('Política de reembolsos para clientes enterprise'),
         ('Guía de onboarding para nuevos empleados'),
         ('Procedimiento de escalamiento de incidentes')
 ) AS d(contenido) ON TRUE
 WHERE f.tenant_id IN (1, 2);
 
 -- --------------------------------------------------------
 -- 5. Índices vectoriales (crear DESPUÉS de cargar datos)
 -- --------------------------------------------------------
 CREATE INDEX ON documentos USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
 
 -- --------------------------------------------------------
 -- 6. Roles de ejemplo para la sección de RBAC
 --    (comentado por defecto: requiere privilegios de superusuario)
 -- --------------------------------------------------------
 -- CREATE ROLE analista_datos_gr NOLOGIN;
 -- GRANT USAGE ON SCHEMA public TO analista_datos_gr;
 -- GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista_datos_gr;
 -- CREATE USER analista_junior_01 WITH PASSWORD 'CambiarEnProduccion2026';
 -- GRANT analista_datos_gr TO analista_junior_01;
 -- REVOKE DELETE ON TABLE ventas FROM analista_datos_gr;
 -- REVOKE CREATE ON SCHEMA public FROM analista_datos_gr;
 
 -- ============================================================
 -- Verificación rápida
 -- ============================================================
 -- SELECT count(*) FROM usuarios;
 -- SELECT count(*) FROM pedidos_modernos;
 -- SELECT count(*) FROM articulos;
 -- SELECT count(*) FROM documentos;

 
