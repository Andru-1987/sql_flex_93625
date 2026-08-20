# Actividad en Clase: Script de Análisis Avanzado con Funciones de Ventana

## 1. Consigna: El Problema de Negocio a Resolver

**Contexto:**
Imagina que trabajas como Analista de Datos para una empresa de retail. La gerencia comercial necesita entender cómo está evolucionando el rendimiento de las distintas categorías de productos a lo largo del tiempo. No solo quieren saber cuánto se vendió, sino que buscan entender el contexto de esas ventas frente a la competencia interna (otras categorías) y frente a su propio historial.

**Objetivo:**
Tu tarea es desarrollar un único script SQL (utilizando CTEs) que genere un reporte analítico completo. Este reporte debe devolver las siguientes columnas:

1. **Mes:** El mes en el que se realizaron las ventas (normalizado al primer día del mes).
2. **Categoría:** El nombre de la categoría del producto.
3. **Venta Total:** El monto total vendido de esa categoría en ese mes.
4. **Ranking del Mes:** La posición de la categoría en ese mes específico, basándose en sus ventas (donde 1 es la categoría que más vendió).
5. **Acumulado (Running Total):** La suma progresiva de las ventas de esa categoría desde el inicio de los registros hasta el mes evaluado.
6. **Comparativa Histórica:** Un mensaje que indique si el rendimiento de ese mes estuvo "Por encima del promedio" o "Por debajo del promedio" histórico de esa misma categoría.

---

## 2. Generación de Base de Datos y Datos de Prueba

Para resolver este ejercicio en clase, primero prepararemos nuestro entorno de trabajo. Copia y ejecuta el siguiente script en tu herramienta de base de datos (pgAdmin o DBeaver) para crear las tablas necesarias e insertar datos de prueba estructurados a lo largo de tres meses.

```sql
-- Eliminar tablas si existen para evitar errores en ejecuciones múltiples
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS categorias;

-- Creación de la tabla Categorías
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Creación de la tabla Productos
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria_id INT REFERENCES categorias(id),
    precio NUMERIC(10, 2) NOT NULL
);

-- Creación de la tabla Ventas
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    fecha DATE NOT NULL,
    cantidad INT NOT NULL
);

-- Inserción de datos de prueba
INSERT INTO categorias (nombre) VALUES 
('Electrónica'), 
('Hogar'), 
('Ferretería');

INSERT INTO productos (nombre, categoria_id, precio) VALUES 
('Televisor 50"', 1, 500.00),
('Laptop', 1, 800.00),
('Licuadora', 2, 50.00),
('Microondas', 2, 120.00),
('Taladro', 3, 90.00);

-- Ventas de Enero 2024
INSERT INTO ventas (producto_id, fecha, cantidad) VALUES 
(1, '2024-01-10', 5),  -- Electrónica: 2500
(2, '2024-01-15', 2),  -- Electrónica: 1600 (Total Ene: 4100)
(3, '2024-01-12', 10), -- Hogar: 500
(5, '2024-01-20', 15); -- Ferretería: 1350

-- Ventas de Febrero 2024
INSERT INTO ventas (producto_id, fecha, cantidad) VALUES 
(1, '2024-02-05', 2),  -- Electrónica: 1000
(4, '2024-02-14', 20), -- Hogar: 2400 (Total Feb: 2400)
(5, '2024-02-22', 10); -- Ferretería: 900

-- Ventas de Marzo 2024
INSERT INTO ventas (producto_id, fecha, cantidad) VALUES 
(2, '2024-03-01', 5),  -- Electrónica: 4000
(3, '2024-03-10', 15), -- Hogar: 750
(4, '2024-03-15', 5),  -- Hogar: 600 (Total Mar: 1350)
(5, '2024-03-25', 12); -- Ferretería: 1080

```

---

## 3. Resolución del Ejercicio

A continuación, se presenta la consulta avanzada que resuelve el problema planteado, estructurada lógicamente mediante Common Table Expressions (CTEs) y aplicando Funciones de Ventana.

```sql
-- Paso 1: Agrupar y calcular las ventas totales por mes y por categoría
WITH ventas_mensuales AS (
    SELECT 
        DATE_TRUNC('month', v.fecha) AS mes_venta,
        c.nombre AS nombre_categoria,
        SUM(v.cantidad * p.precio) AS monto_total
    FROM ventas v
    INNER JOIN productos p ON v.producto_id = p.id
    INNER JOIN categorias c ON p.categoria_id = c.id
    GROUP BY 
        DATE_TRUNC('month', v.fecha),
        c.nombre
),

-- Paso 2: Calcular métricas avanzadas (Ranking, Acumulado y Promedio) usando Funciones de Ventana
metricas_ventana AS (
    SELECT 
        mes_venta,
        nombre_categoria,
        monto_total,
        
        -- Ranking de categorías dentro de un mismo mes (se reinicia cada mes)
        RANK() OVER (PARTITION BY mes_venta ORDER BY monto_total DESC) AS ranking_mensual,
        
        -- Total acumulado de ventas para cada categoría a lo largo del tiempo
        SUM(monto_total) OVER (PARTITION BY nombre_categoria ORDER BY mes_venta) AS ventas_acumuladas,
        
        -- Promedio histórico de ventas por categoría (sin ORDER BY para tomar todo el historial)
        AVG(monto_total) OVER (PARTITION BY nombre_categoria) AS promedio_historico
    FROM ventas_mensuales
)

-- Paso 3: Selección final aplicando lógica condicional de negocio
SELECT 
    mes_venta,
    nombre_categoria,
    monto_total,
    ranking_mensual,
    ventas_acumuladas,
    CASE 
        WHEN monto_total >= promedio_historico THEN 'Por encima o igual al promedio'
        ELSE 'Por debajo del promedio'
    END AS comparativa_rendimiento
FROM metricas_ventana
ORDER BY 
    mes_venta ASC, 
    ranking_mensual ASC;

```

### Explicación de la Lógica Aplicada:

1. **CTE `ventas_mensuales**`: Realiza el trabajo fundacional (la "mise en place"). Cruza las tres tablas y colapsa los datos diarios en totales mensuales por categoría utilizando `DATE_TRUNC` y `SUM`.
2. **CTE `metricas_ventana**`: Utiliza el resultado agrupado anterior para calcular operaciones complejas sin perder registros. El `RANK()` se particiona por mes para evaluar competencia interna, mientras que el `SUM()` y `AVG()` se particionan por categoría para evaluar el rendimiento temporal del producto. El `ORDER BY` dentro del `OVER` del `SUM` es crítico para lograr el efecto acumulativo progresivo.
3. **Consulta Final**: Formatea la salida y aplica un `CASE WHEN` que inyecta la regla de negocio solicitada, comparando dinámicamente el rendimiento del mes actual contra el promedio histórico precalculado en la CTE anterior.