# Material Práctico para la Clase: Desafío de Rankings de Producto

## 1. Consigna: El Problema de Negocio a Resolver

**Contexto:**
Somos el equipo de analítica de un eCommerce en pleno crecimiento. El equipo de Marketing está armando una campaña publicitaria segmentada y necesita saber cuáles son los productos "Top Sellers" para promocionarlos.

**Objetivo:**
Escribir una consulta SQL que devuelva un reporte con los **3 productos más vendidos (en cantidad total)** por cada una de las categorías.
El reporte final debe contener:

* Nombre de la categoría.
* Nombre del producto.
* Cantidad total vendida de ese producto.
* La posición (Ranking) que ocupa ese producto dentro de su categoría.

*Nota técnica:* Es altamente probable que existan empates en las cantidades vendidas. El ranking no debe dejar saltos numéricos si dos productos empatan en la misma posición.

---

## 2. Generación de Base de Datos y Datos de Prueba

Ejecuta el siguiente bloque SQL para crear el entorno de prueba. Este script incluye empates intencionales para forzar la necesidad de usar funciones de ranking específicas.

```sql
-- Limpieza del entorno
DROP TABLE IF EXISTS ventas_ecommerce;
DROP TABLE IF EXISTS productos_ecommerce;
DROP TABLE IF EXISTS categorias_ecommerce;

-- Creación de tablas
CREATE TABLE categorias_ecommerce (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50)
);

CREATE TABLE productos_ecommerce (
    id_producto SERIAL PRIMARY KEY,
    id_categoria INT REFERENCES categorias_ecommerce(id_categoria),
    nombre_producto VARCHAR(100)
);

CREATE TABLE ventas_ecommerce (
    id_venta SERIAL PRIMARY KEY,
    id_producto INT REFERENCES productos_ecommerce(id_producto),
    cantidad_vendida INT
);

-- Inserción de Categorías
INSERT INTO categorias_ecommerce (nombre_categoria) 
VALUES ('Smartphones'), ('Audio');

-- Inserción de Productos
INSERT INTO productos_ecommerce (id_categoria, nombre_producto) VALUES 
(1, 'iPhone 13'),
(1, 'Samsung Galaxy S22'),
(1, 'Xiaomi Redmi Note 11'),
(1, 'Motorola Edge 30'),
(1, 'Google Pixel 6'),
(2, 'Auriculares Sony WH-1000XM4'),
(2, 'AirPods Pro'),
(2, 'JBL Flip 5'),
(2, 'Bose QuietComfort 45');

-- Inserción de Ventas (Con empates planificados)
INSERT INTO ventas_ecommerce (id_producto, cantidad_vendida) VALUES 
-- Ventas Smartphones
(1, 150), (1, 50),   -- iPhone: 200 total
(2, 200),            -- Samsung: 200 total (Empate en puesto 1)
(3, 180),            -- Xiaomi: 180 total (Puesto 2)
(4, 150),            -- Motorola: 150 total (Puesto 3)
(5, 90),             -- Pixel: 90 total (Queda fuera del top 3)
-- Ventas Audio
(6, 300),            -- Sony: 300 total (Puesto 1)
(7, 250),            -- AirPods: 250 total (Puesto 2)
(8, 250),            -- JBL: 250 total (Empate en puesto 2)
(9, 100);            -- Bose: 100 total (Puesto 3)

```

---

## 3. Resolución del Ejercicio

Para resolver este desafío de manera limpia, utilizaremos dos CTEs secuenciales y la función de ventana `DENSE_RANK()`.

```sql
-- Paso 1: Consolidar las ventas totales por producto y categoría
WITH total_por_producto AS (
    SELECT 
        c.nombre_categoria,
        p.nombre_producto,
        SUM(v.cantidad_vendida) AS total_vendido
    FROM ventas_ecommerce v
    INNER JOIN productos_ecommerce p ON v.id_producto = p.id_producto
    INNER JOIN categorias_ecommerce c ON p.id_categoria = c.id_categoria
    GROUP BY 
        c.nombre_categoria,
        p.nombre_producto
),

-- Paso 2: Aplicar la función de ventana para generar el ranking
ranking_productos AS (
    SELECT 
        nombre_categoria,
        nombre_producto,
        total_vendido,
        DENSE_RANK() OVER(
            PARTITION BY nombre_categoria 
            ORDER BY total_vendido DESC
        ) AS puesto_categoria
    FROM total_por_producto
)

-- Paso 3: Filtrar para obtener solo el Top 3 por categoría
SELECT 
    nombre_categoria,
    nombre_producto,
    total_vendido,
    puesto_categoria
FROM ranking_productos
WHERE puesto_categoria <= 3
ORDER BY 
    nombre_categoria, 
    puesto_categoria;

```

### Explicación de la Lógica Aplicada:

1. **CTE `total_por_producto**`: Agrupa y suma la cantidad de ventas a nivel producto, trayendo el nombre de la categoría para segmentar más adelante.
2. **CTE `ranking_productos**`: Es vital hacer el cálculo del ranking en una etapa separada. Se utiliza `DENSE_RANK()` porque si dos productos venden exactamente lo mismo (como el iPhone y el Samsung en este ejemplo), ambos ocuparán el puesto 1, y el siguiente producto ocupará el puesto 2 de manera compacta. El `PARTITION BY nombre_categoria` asegura que el contador vuelva a 1 al evaluar una categoría nueva.
3. **Consulta Principal**: Las funciones de ventana no se pueden colocar directamente en un bloque `WHERE`. Al haber resuelto el ranking dentro de una CTE previa, la consulta final simplemente filtra buscando a los que obtuvieron las medallas 1, 2 y 3 (`<= 3`).