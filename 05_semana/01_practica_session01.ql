# Material Práctico para la Clase: El Reporte Maestro (Crecimiento Mes a Mes)

A continuación, se presenta el desarrollo de la **Actividad 1** estructurado como problema de negocio, generación de datos y su resolución óptima, ideal para modelar en vivo con los alumnos.

## 1. Consigna: El Problema de Negocio a Resolver

**Contexto:**
El equipo financiero de nuestra plataforma de E-Commerce necesita analizar la salud del negocio. Quieren entender si las ventas de nuestras distintas categorías de productos están creciendo o disminuyendo mes a mes.

**Objetivo:**
Construir un script SQL estructurado en CTEs que calcule el crecimiento de ventas mensual por categoría.
El reporte final debe devolver:

1. El mes analizado.
2. La categoría del producto.
3. El total de ventas de ese mes.
4. El total de ventas del mes inmediatamente anterior para esa misma categoría (usando Funciones de Ventana).
5. La diferencia en ingresos (Crecimiento o Caída) respecto al mes anterior.

---

## 2. Generación de Base de Datos y Datos de Prueba

Ejecuta el siguiente bloque SQL para crear el entorno de prueba con datos simulados a lo largo de tres meses, lo que permitirá ver el efecto de la función de desplazamiento temporal.

```sql
-- Limpieza del entorno
DROP TABLE IF EXISTS ventas_mes;
DROP TABLE IF EXISTS productos_ecommerce;
DROP TABLE IF EXISTS categorias_ecommerce;

-- Creación de tablas
CREATE TABLE categorias_ecommerce (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE productos_ecommerce (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    id_categoria INT REFERENCES categorias_ecommerce(id_categoria),
    precio NUMERIC(10,2)
);

CREATE TABLE ventas_mes (
    id_venta SERIAL PRIMARY KEY,
    id_producto INT REFERENCES productos_ecommerce(id_producto),
    fecha DATE,
    cantidad INT
);

-- Inserción de Categorías y Productos
INSERT INTO categorias_ecommerce (nombre) VALUES ('Tecnología'), ('Muebles');

INSERT INTO productos_ecommerce (nombre, id_categoria, precio) VALUES 
('Laptop', 1, 1000.00),
('Monitor', 1, 300.00),
('Silla Ergonomica', 2, 150.00),
('Escritorio', 2, 250.00);

-- Inserción de Ventas (Enero, Febrero y Marzo)
INSERT INTO ventas_mes (id_producto, fecha, cantidad) VALUES 
-- Enero
(1, '2024-01-10', 10), -- Tec: 10000
(3, '2024-01-15', 20), -- Muebles: 3000
-- Febrero
(1, '2024-02-05', 12), -- Tec: 12000 (Sube)
(2, '2024-02-10', 10), -- Tec: 3000 (Total Tec Feb: 15000)
(4, '2024-02-20', 10), -- Muebles: 2500 (Baja)
-- Marzo
(2, '2024-03-05', 5),  -- Tec: 1500 (Baja drástica)
(3, '2024-03-12', 30), -- Muebles: 4500 (Sube)
(4, '2024-03-25', 15); -- Muebles: 3750 (Total Muebles Mar: 8250)

```

---

## 3. Resolución del Ejercicio

La solución óptima divide el problema en dos pasos lógicos usando CTEs y aplica la función `LAG()` para la retrospectiva temporal.

```sql
-- Paso 1: Agregación base - Ventas totales por mes y categoría
WITH ventas_agrupadas AS (
    SELECT 
        DATE_TRUNC('month', v.fecha) AS mes_venta,
        c.nombre AS categoria,
        SUM(v.cantidad * p.precio) AS total_ingresos
    FROM ventas_mes v
    INNER JOIN productos_ecommerce p ON v.id_producto = p.id_producto
    INNER JOIN categorias_ecommerce c ON p.id_categoria = c.id_categoria
    GROUP BY 
        DATE_TRUNC('month', v.fecha),
        c.nombre
),

-- Paso 2: Análisis temporal usando LAG para traer el mes anterior
analisis_tendencia AS (
    SELECT 
        mes_venta,
        categoria,
        total_ingresos,
        LAG(total_ingresos) OVER(
            PARTITION BY categoria 
            ORDER BY mes_venta
        ) AS ingresos_mes_anterior
    FROM ventas_agrupadas
)

-- Paso 3: Cálculo final del rendimiento (Lógica de negocio)
SELECT 
    TO_CHAR(mes_venta, 'YYYY-MM') AS periodo,
    categoria,
    total_ingresos,
    COALESCE(ingresos_mes_anterior, 0) AS ingresos_mes_anterior,
    COALESCE(total_ingresos - ingresos_mes_anterior, total_ingresos) AS diferencia_crecimiento,
    CASE 
        WHEN ingresos_mes_anterior IS NULL THEN 'Mes Base'
        WHEN total_ingresos > ingresos_mes_anterior THEN 'Crecimiento'
        WHEN total_ingresos < ingresos_mes_anterior THEN 'Caída'
        ELSE 'Estancamiento'
    END AS estado_rendimiento
FROM analisis_tendencia
ORDER BY 
    categoria, 
    mes_venta;

```

### Explicación de la Lógica Aplicada:

1. **CTE `ventas_agrupadas**`: Normaliza las fechas al inicio del mes utilizando `DATE_TRUNC` y consolida la métrica financiera multiplicando precio por cantidad. Prepara el terreno limpiando la base.
2. **CTE `analisis_tendencia**`: Aprovecha la función `LAG()` para mirar hacia el "espejo retrovisor". El `PARTITION BY categoria` es crítico aquí; asegura que comparemos peras con peras (la tecnología de febrero solo se compara con la tecnología de enero, no cruza datos con muebles). El `ORDER BY mes_venta` garantiza el orden cronológico estricto.
3. **Consulta Final**: Formatea la salida y maneja los valores `NULL` del primer mes usando `COALESCE`. Implementa un bloque condicional `CASE WHEN` para traducir los números matemáticos en etiquetas de negocio (Crecimiento, Caída o Mes Base) fáciles de leer para la gerencia.