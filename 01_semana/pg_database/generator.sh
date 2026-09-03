#!/bin/bash

# Configuración de variables (Ajustar según el entorno de los alumnos)
DB_USER="postgres"
DB_NAME="postgres"
HOST="localhost"

echo "Creando tabla y generando 1.000.000 de registros. Esto tomará unos segundos..."

psql -U $DB_USER -h $HOST -d $DB_NAME -c "
-- 1. Limpiar ejercicios anteriores si existen
DROP TABLE IF EXISTS ventas_clase CASCADE;
DROP MATERIALIZED VIEW IF EXISTS reporte_mensual_mat;
DROP VIEW IF EXISTS reporte_mensual_view;

-- 2. Crear tabla base (Sin índices, estado puro)
CREATE TABLE ventas_clase (
    id SERIAL PRIMARY KEY,
    cliente_id INT,
    monto DECIMAL(10,2),
    fecha TIMESTAMP,
    estado VARCHAR(20),
    metadata JSONB
);

-- 3. Insertar 1 Millón de filas usando generate_series
INSERT INTO ventas_clase (cliente_id, monto, fecha, estado, metadata)
SELECT 
    trunc(random() * 50000 + 1), -- 50,000 clientes distintos
    (random() * 5000)::decimal(10,2), -- Montos aleatorios
    timestamp '2024-01-01 00:00:00' + random() * (timestamp '2026-08-01 00:00:00' - timestamp '2024-01-01 00:00:00'),
    CASE 
        WHEN random() < 0.70 THEN 'COMPLETADO' 
        WHEN random() < 0.90 THEN 'PENDIENTE' 
        ELSE 'CANCELADO' 
    END,
    ('{\"origen\": \"' || (ARRAY['WEB', 'APP', 'TIENDA'])[floor(random()*3)+1] || '\"}')::jsonb
FROM generate_series(1, 1000000);

-- 4. Deshabilitar el autovacuum para esta tabla (Solo con fines educativos para el Ejercicio 2)
ALTER TABLE ventas_clase SET (autovacuum_enabled = false);
"

echo "Base de datos lista para la clase."

