### Preparación del Entorno (Script de Generación de Datos)

Este script de Bash se conecta a PostgreSQL y crea una tabla `ventas_clase` con **1 millón de registros aleatorios**. Se crea deliberadamente sin índices y sin optimizaciones.

Crea un archivo llamado `generar_datos.sh`:

```bash
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

```

---

### Ejercicio 1: El Abismo del *Sequential Scan* vs el *Index Scan*

**Objetivo:** Demostrar a los alumnos cómo el Planificador elige leer toda la tabla cuando no hay índices, y cómo el B-Tree cambia radicalmente el rendimiento.

**Paso 1: Ejecutar la consulta lenta (Sin optimizar)**
Pide a los alumnos que busquen las compras de un cliente específico utilizando `EXPLAIN ANALYZE`:

```sql
EXPLAIN ANALYZE 
SELECT * FROM ventas_clase WHERE cliente_id = 15432;

```

*Lo que deben observar:*

* **Node Type:** `Seq Scan` (El motor leyó 1 millón de filas).
* **Execution Time:** Rondará entre 50ms y 150ms (dependiendo del hardware). Parece rápido, pero si tuvieran 1,000 usuarios haciendo esto al mismo tiempo, el servidor colapsaría.

**Paso 2: Crear la optimización (B-Tree)**

```sql
CREATE INDEX idx_cliente_id ON ventas_clase(cliente_id);

```

**Paso 3: Volver a ejecutar y comparar**

```sql
EXPLAIN ANALYZE 
SELECT * FROM ventas_clase WHERE cliente_id = 15432;

```

*Lo que deben observar:*

* **Node Type:** `Bitmap Heap Scan` o `Index Scan`.
* **Execution Time:** Bajaría a **0.05ms** o menos. Una mejora del rendimiento abismal (más del 1000% más rápido).

---

### Ejercicio 2: MVCC, Tuplas Muertas y Bloat

**Objetivo:** Mostrar físicamente cómo un `UPDATE` en PostgreSQL no actualiza la fila, sino que crea una nueva, inflando el tamaño del disco.

**Paso 1: Medir el tamaño físico actual de la tabla**

```sql
SELECT pg_size_pretty(pg_relation_size('ventas_clase')) AS tamaño_inicial;

```

*(Anotar el tamaño en la pizarra, por ejemplo: 75 MB).*

**Paso 2: Generar una actualización masiva (Simulando un proceso de fin de mes)**
Vamos a actualizar los estados 'PENDIENTE' a 'COMPLETADO'. Esto afectará a unos 200,000 registros (20% de la tabla).

```sql
UPDATE ventas_clase SET estado = 'COMPLETADO' WHERE estado = 'PENDIENTE';

```

**Paso 3: Volver a medir el tamaño**

```sql
SELECT pg_size_pretty(pg_relation_size('ventas_clase')) AS tamaño_post_update;

```

*Lo que deben observar:* ¡La tabla creció sustancialmente! (Ej. pasó a 90 MB). Esto ocurre porque las 200,000 filas originales ahora son "tuplas muertas" (Bloat).

**Paso 4: Limpiar con VACUUM**

```sql
VACUUM VERBOSE ventas_clase;

```

*Nota didáctica:* Explica que `VACUUM` normal no reduce el peso del archivo físico para el sistema operativo (no baja los MB), pero marca ese espacio interno como libre para que los futuros `INSERT` lo reutilicen. (Si quieren recuperar el espacio en disco, deben usar `VACUUM FULL`, pero aclara que bloquea la tabla entera).

---

### Ejercicio 3: Índices GIN en Datos Complejos (JSONB)

**Objetivo:** Enseñar que el B-Tree no sirve para todo, especialmente cuando usamos arquitecturas modernas con campos JSON no estructurados.

**Paso 1: Buscar dentro del JSON sin índice**
Queremos todas las ventas cuyo origen fue la 'APP'.

```sql
EXPLAIN ANALYZE 
SELECT * FROM ventas_clase WHERE metadata ->> 'origen' = 'APP';

```

*Resultado:* Otro `Seq Scan` masivo.

**Paso 2: Crear el índice GIN**

```sql
CREATE INDEX idx_metadata_gin ON ventas_clase USING GIN (metadata);

```

**Paso 3: Consultar utilizando operadores JSONB**
Para que el Planificador use el índice GIN, debemos usar la sintaxis de contención `@>` en lugar de `->>`.

```sql
EXPLAIN ANALYZE 
SELECT * FROM ventas_clase WHERE metadata @> '{"origen": "APP"}';

```

*Resultado:* Pasa a un `Bitmap Index Scan` ultrarrápido.


--- 

#### CASO PUNTUAL DE USO

Cuando realmente GIN se luce
```sql
UPDATE ventas_clase 
SET metadata = metadata || '{"cupon_secreto": "GOLDEN-2026"}'::jsonb
WHERE id IN (150, 4800, 9999, 500000, 850000);
```

**La búsqueda ineficiente (Forzando el Seq Scan)**

Ahora, busquemos a esos 5 afortunados usando el operador de extracción de texto ->>, el cual no puede usar el índice GIN.

**La búsqueda ineficiente (Forzando el Seq Scan)**

```sql
EXPLAIN ANALYZE 
SELECT * FROM ventas_clase 
WHERE metadata ->> 'cupon_secreto' = 'GOLDEN-2026';

vs

EXPLAIN ANALYZE 
SELECT * FROM ventas_clase 
WHERE metadata @> '{"cupon_secreto": "GOLDEN-2026"}'::jsonb;

```

---

### Ejercicio 4: Vistas vs Vistas Materializadas

**Objetivo:** Demostrar cómo salvar la CPU en reportes pesados de tableros de control (Dashboards).

**Paso 1: Crear una vista tradicional y medirla**
Esta vista agrupa por mes y suma los montos (un trabajo pesado de agregación).

```sql
CREATE VIEW reporte_mensual_view AS
SELECT 
    date_trunc('month', fecha) as mes, 
    COUNT(*) as total_ventas,
    SUM(monto) as ingresos_totales
FROM ventas_clase
GROUP BY 1;

EXPLAIN ANALYZE SELECT * FROM reporte_mensual_view;

```

*Resultado:* El motor recalcula la suma sobre el millón de filas en el momento. Tiempo de ejecución elevado (ej. 300ms).

**Paso 2: Crear la Vista Materializada**

```sql
CREATE MATERIALIZED VIEW reporte_mensual_mat AS
SELECT 
    date_trunc('month', fecha) as mes, 
    COUNT(*) as total_ventas,
    SUM(monto) as ingresos_totales
FROM ventas_clase
GROUP BY 1;

EXPLAIN ANALYZE SELECT * FROM reporte_mensual_mat;

```

*Resultado:* ¡Tiempo de ejecución casi en **0.01ms**! El motor simplemente leyó una tabla estática ya procesada.

**Paso 3 (Cierre): El costo de la Vista Materializada**
Para finalizar, haz un `INSERT` de un nuevo registro en la tabla original y muestra que la `reporte_mensual_mat` NO tiene ese dato, introduciendo el concepto de que deben refrescarse:

```sql
REFRESH MATERIALIZED VIEW reporte_mensual_mat;

```
