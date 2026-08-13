# Practica en vivo para clase

**Objetivo:** Poner en práctica el pensamiento analítico para resolver problemas de negocio reales y "misterios" de datos. Deberás utilizar consultas multicapa, combinar múltiples tablas (JOINS) y aplicar agrupaciones estratégicas (GROUP BY y HAVING), evitando la trampa de los duplicados.

**Instrucciones del Ejercicio:**
A partir del esquema de base de datos proporcionado, deberás construir tres reportes específicos. Imagina que eres un analista de datos y te han pedido auditar el negocio.

1. **Investigación:** Debes rastrear el origen de un registro anómalo.
2. **Dashboard:** Debes consolidar las ventas y aplicar filtros condicionales sobre métricas agrupadas.
3. **Auditoría:** Debes encontrar los "huecos" de información utilizando la exclusión lógica.

---

## Enviroment para copiar y pegar: SQL DDL + INSERT DATA

Ejecuta el siguiente bloque en tu herramienta de gestión de base de datos para preparar tu entorno de trabajo.

```sql
-- DDL: Creación de tablas (Ordenadas para respetar Claves Foráneas)
CREATE TABLE locales (
    id SERIAL PRIMARY KEY,
    ciudad VARCHAR(100) NOT NULL
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    local_id INT REFERENCES locales(id)
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(100) NOT NULL
);

CREATE TABLE proveedores (
    id SERIAL PRIMARY KEY,
    nombre_proveedor VARCHAR(100) NOT NULL
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    proveedor_id INT REFERENCES proveedores(id),
    categoria_id INT REFERENCES categorias(id)
);

CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    empleado_id INT REFERENCES empleados(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT NOT NULL,
    fecha DATE NOT NULL
);

-- DML: Inserción de datos de prueba
INSERT INTO locales (ciudad) VALUES 
('Buenos Aires'), 
('Córdoba'), 
('Rosario');

INSERT INTO empleados (nombre, local_id) VALUES 
('Laura Gómez', 1),
('Martín Silva', 2),
('Sofía Torres', 3);

INSERT INTO categorias (nombre_categoria) VALUES 
('Tecnología'), 
('Mobiliario'), 
('Línea Blanca');

INSERT INTO proveedores (nombre_proveedor) VALUES 
('TechCorp Solutions'), 
('Maderas del Sur'), 
('ElectroMundo');

INSERT INTO productos (nombre, precio, proveedor_id, categoria_id) VALUES 
('Notebook Pro', 1500.00, 1, 1),
('Escritorio Ejecutivo', 350.00, 2, 2),
('Monitor 32"', 400.00, 1, 1),
('Silla Gamer', 250.00, 2, 2),
('Heladera Smart', 1200.00, 3, 3); -- Producto que nunca se venderá (Inventario Fantasma)

INSERT INTO ventas (empleado_id, producto_id, cantidad, fecha) VALUES 
(1, 1, 2, '2023-10-01'), -- Venta normal
(2, 2, 4, '2023-10-05'), -- Venta normal
(1, 3, 5, '2023-10-10'), -- Venta normal
(3, 1, 50, '2023-10-31'); -- Venta SOSPECHOSA (Monto excesivo)

```

---

## Preguntas a responder

1. **El Detective de Datos (JOINS en acción):** El equipo de auditoría ha detectado una transacción anómala (una venta donde la cantidad de artículos superó las 40 unidades en un solo ticket). Tu misión es unir la tabla de ventas, empleados y locales para descubrir: ¿Quién fue el empleado responsable de esta venta y en qué ciudad ocurrió?
2. **Dashboard de Ventas Multicapa:** El área comercial necesita saber el total de ingresos brutos por categoría. Debes unir las tablas necesarias para calcular el total vendido (cantidad * precio) por cada categoría, pero **solo** debes mostrar aquellas categorías cuyo ingreso total haya superado la meta de los $10,000.
3. **El Desafío del Inventario Fantasma:** Logística sospecha que hay artículos ocupando espacio en el depósito que jamás han salido. Utiliza un `LEFT JOIN` para identificar qué productos **nunca** han registrado una venta. Muestra el nombre del producto y el nombre de su proveedor para exigir explicaciones.

---

## SQL respuesta con su documentacion como comentario

```sql
-- ==============================================================================
-- 1. EL DETECTIVE DE DATOS
-- ==============================================================================
-- Problema: Rastrear el origen de una transacción sospechosa (cantidad > 40).
-- Solución: Se utiliza INNER JOIN para navegar por la jerarquía de dependencias 
-- desde la tabla transaccional (ventas) hacia las tablas dimensionales 
-- (empleados y locales) para extraer el contexto del registro anómalo.

SELECT 
    e.nombre AS empleado_responsable,
    l.ciudad AS ubicacion_local,
    v.cantidad AS unidades_vendidas,
    v.fecha
FROM ventas AS v
INNER JOIN empleados AS e 
    ON v.empleado_id = e.id
INNER JOIN locales AS l 
    ON e.local_id = l.id
WHERE 
    v.cantidad > 40;


-- ==============================================================================
-- 2. DASHBOARD DE VENTAS MULTICAPA
-- ==============================================================================
-- Problema: Evaluar el rendimiento de las categorías y filtrar las exitosas.
-- Solución: Se agrupan los datos por categoría y se calcula el ingreso.
-- CRÍTICO: La condición del objetivo comercial (> $10,000) debe ir obligatoriamente
-- en la cláusula HAVING, ya que estamos evaluando el resultado de una 
-- función de agregación (SUM) y no filas individuales.

SELECT 
    c.nombre_categoria,
    SUM(v.cantidad * p.precio) AS ingresos_totales
FROM ventas AS v
INNER JOIN productos AS p 
    ON v.producto_id = p.id
INNER JOIN categorias AS c 
    ON p.categoria_id = c.id
GROUP BY 
    c.nombre_categoria
HAVING 
    SUM(v.cantidad * p.precio) > 10000;


-- ==============================================================================
-- 3. EL DESAFÍO DEL INVENTARIO FANTASMA
-- ==============================================================================
-- Problema: Identificar inventario inmovilizado y a su proveedor.
-- Solución: El LEFT JOIN es la herramienta táctica ideal aquí. Se listan TODOS 
-- los productos y se cruzan con las ventas. Aquellos productos que NO cruzaron 
-- (es decir, el ID de la venta es NULL) son los artículos que jamás se vendieron.

SELECT 
    p.nombre AS producto_sin_ventas,
    prov.nombre_proveedor AS proveedor_contacto
FROM productos AS p
LEFT JOIN ventas AS v 
    ON p.id = v.producto_id
INNER JOIN proveedores AS prov 
    ON p.proveedor_id = prov.id
WHERE 
    v.id IS NULL;

```