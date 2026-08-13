# Practica en clase

**Objetivo:** Extraer inteligencia de negocio combinando múltiples tablas mediante el uso de `JOINs`, `GROUP BY` y `HAVING` en PostgreSQL.

**Instrucciones del Ejercicio:**
Debes crear un script SQL que resuelva tres problemas analíticos de negocio específicos. Deberás interconectar las tablas de tu base de datos para generar reportes estructurados que ayuden a la toma de decisiones.

**Reglas estandarizadas para el código:**

1. Al menos una consulta debe unir 3 o más tablas.
2. Uso obligatorio de alias para todas las tablas (ej. `v` para ventas, `c` para clientes).
3. Evitar la ambigüedad de columnas especificando siempre su origen (ej. `c.nombre`, `p.nombre`).
4. Toda columna en el `SELECT` que no esté dentro de una función de agregación debe estar en el `GROUP BY`.
5. Los filtros basados en funciones de agregación (`SUM`, `COUNT`) deben ir obligatoriamente en la cláusula `HAVING`.
6. Las consultas que utilicen `LEFT JOIN` deben manejar los valores nulos con la función `COALESCE`.
7. Cada consulta debe incluir un comentario inicial explicando el problema de negocio que resuelve.

---

## Enviroment para copiar y pegar: SQL DDL + INSERT DATA

Ejecuta el siguiente bloque en tu herramienta (pgAdmin, DBeaver) para recrear el entorno del ejercicio.

```sql
-- DDL: Creación de tablas
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    categoria_id INT REFERENCES categorias(id)
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_registro DATE NOT NULL
);

CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT NOT NULL,
    fecha DATE NOT NULL
); 

-- DML: Inserción de datos de prueba
INSERT INTO categorias (nombre) VALUES 
('Electrónica'), ('Hogar'), ('Oficina'), ('Deportes');

INSERT INTO productos (nombre, precio, categoria_id) VALUES 
('Laptop Pro', 1200.00, 1),
('Monitor 27"', 300.00, 1),
('Silla Ergonómica', 150.00, 3),
('Escritorio', 200.00, 3),
('Cafetera', 80.00, 2),
('Bicicleta', 450.00, 4);

INSERT INTO clientes (nombre, email, fecha_registro) VALUES 
('Ana García', 'ana@email.com', '2023-01-15'),
('Carlos López', 'carlos@email.com', '2023-02-20'),
('María Rodríguez', 'maria@email.com', '2023-03-10'),
('Juan Pérez', 'juan@email.com', '2023-04-05'); -- Cliente sin compras

INSERT INTO ventas (cliente_id, producto_id, cantidad, fecha) VALUES 
(1, 1, 1, '2023-05-10'),
(1, 2, 2, '2023-05-12'),
(1, 2, 1, '2023-06-01'),
(2, 3, 4, '2023-05-15'),
(2, 4, 1, '2023-05-20'),
(3, 5, 1, '2023-06-10'),
(3, 5, 2, '2023-07-15');

```

---

## Preguntas a responder

A partir del esquema generado, debes estructurar consultas SQL para resolver los siguientes requerimientos:

1. **Rentabilidad por categoría:** Une las tablas de ventas, productos y categorías. Muestra el nombre de la categoría, las unidades totales vendidas y el ingreso total generado. Filtra el resultado para mostrar únicamente las categorías cuyo ingreso total supere los $500.
2. **Clientes sin compras (Clientes Escurridizos):** Utilizando un `LEFT JOIN`, identifica a los clientes registrados en la plataforma que aún no han realizado ninguna transacción. Muestra un "0" en lugar de un valor nulo para sus cantidades compradas.
3. **Top de compras por cliente:** Une clientes, ventas y productos. Muestra el nombre del cliente, el nombre del producto que más cantidad compró y la fecha de la última transacción que hizo de dicho producto.

---

## SQL respuesta con su documentacion como comentario

Copia este código en tu archivo `pre-entrega-modulo4.sql`.

```sql
-- ==============================================================================
-- 1. RENTABILIDAD POR CATEGORÍA
-- ==============================================================================
-- Problema de negocio que resuelve: 
-- Permite al equipo directivo identificar qué segmentos de mercado (categorías) 
-- son los más rentables y cruzan el umbral de viabilidad (ingresos > $500). 
-- Esta métrica es fundamental para asignar presupuestos de marketing de forma 
-- eficiente hacia las categorías estrella y auditar aquellas de bajo rendimiento.

SELECT 
    cat.nombre AS nombre_categoria,
    SUM(v.cantidad) AS unidades_vendidas,
    SUM(v.cantidad * p.precio) AS ingreso_total
FROM ventas AS v
INNER JOIN productos AS p 
    ON v.producto_id = p.id
INNER JOIN categorias AS cat 
    ON p.categoria_id = cat.id
GROUP BY 
    cat.nombre
HAVING 
    SUM(v.cantidad * p.precio) > 500;


-- ==============================================================================
-- 2. CLIENTES SIN COMPRAS (CLIENTES ESCURRIDIZOS)
-- ==============================================================================
-- Problema de negocio que resuelve: 
-- Identifica a los prospectos que han demostrado interés (se registraron) pero 
-- que no han completado el embudo de conversión (cero compras). Este listado 
-- es el insumo principal para ejecutar campañas de re-targeting, ofreciendo 
-- cupones de descuento para incentivar su primera compra.

SELECT 
    c.nombre AS nombre_cliente,
    c.email,
    COALESCE(SUM(v.cantidad), 0) AS total_unidades_compradas
FROM clientes AS c
LEFT JOIN ventas AS v 
    ON c.id = v.cliente_id
GROUP BY 
    c.id, 
    c.nombre, 
    c.email
HAVING 
    COUNT(v.id) = 0;


-- ==============================================================================
-- 3. TOP DE COMPRAS POR CLIENTE
-- ==============================================================================
-- Problema de negocio que resuelve: 
-- Construye un perfil de consumo por cliente al identificar su producto 
-- favorito (el que más unidades ha comprado) y determinar su nivel de actividad 
-- reciente (fecha de última transacción). Vital para motores de recomendación 
-- y análisis de retención de clientes.

-- Nota técnica: Se utiliza DISTINCT ON, una característica nativa y eficiente 
-- de PostgreSQL, para extraer exclusivamente la primera fila de cada cliente 
-- tras ordenar por la cantidad total comprada de forma descendente.

SELECT DISTINCT ON (c.id)
    c.nombre AS nombre_cliente,
    p.nombre AS producto_mas_comprado,
    SUM(v.cantidad) AS cantidad_total,
    MAX(v.fecha) AS fecha_ultima_transaccion
FROM clientes AS c
INNER JOIN ventas AS v 
    ON c.id = v.cliente_id
INNER JOIN productos AS p 
    ON v.producto_id = p.id
GROUP BY 
    c.id, 
    c.nombre, 
    p.nombre
ORDER BY 
    c.id ASC, 
    cantidad_total DESC;

```