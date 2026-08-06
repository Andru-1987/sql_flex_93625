
# Guión de Clase: Consolidación - Consultas Esenciales y Filtrado de Datos

## 1. Objetivos

**¿Qué aprenderemos hoy?**
* A construir consultas SQL robustas desde cero sin dudar de la sintaxis.
* A identificar y corregir los errores de lógica más comunes al filtrar datos.
* A aplicar funciones de agregación para obtener estadísticas significativas.
* A optimizar el orden y la presentación de los resultados para reportes profesionales.

**Preparación Obligatoria:**
* Tener instalado PostgreSQL y pgAdmin.
* Tener a mano el esquema de la base de datos de ejemplo.

---

## 2. Temas Clave (Explicaciones para la Clase)

**A. Repaso de Estructura (SELECT, FROM y orden de ejecución)**
* Recordar a los alumnos que aunque escribimos `SELECT` primero, el motor de PostgreSQL procesa primero el `FROM`. 
* Esta es la razón por la que no podemos usar un alias creado en el `SELECT` dentro de un `WHERE`.

**B. Maestría en Filtrado (WHERE, lógicos y LIKE)**
* `WHERE` actúa como un embudo antes de realizar cualquier cálculo.
* **Anatomía de LIKE:** `%` representa cualquier cantidad de caracteres (cero o más), mientras que `_` representa exactamente un carácter.
* **Lógica de NULL:** En SQL, `NULL` significa "desconocido". Por lo tanto, preguntar si algo es igual a desconocido (`columna = NULL`) siempre es falso. La forma correcta es usar `IS NULL` o `IS NOT NULL`.

**C. Gestión de Agregados (COUNT, SUM, WHERE vs HAVING)**
* **Filtro antes vs. después:** `WHERE` filtra filas individuales *antes* de agruparlas. `HAVING` filtra los grupos una vez que ya han sido creados por `GROUP BY`.
* Si necesitamos filtrar por el total de ventas, obligatoriamente debemos usar `HAVING SUM(ventas) > X`.

**D. Limpieza de Datos (COALESCE)**
* El poder de `COALESCE`: Transforma el "Vacío" (`NULL`) en algo útil (ej. 'Sin Nombre' o '0') para mantener los reportes limpios y evitar errores matemáticos.

---

## 3. Dinámicas de la Clase

### Actividad 1: El Caza-Errores (Bug Hunt) - 20 min
**Dinámica:** 2 minutos de observación silenciosa, votación rápida, 3 minutos de resolución en vivo.
**Troubleshooting:** Si nadie identifica el error, dar una pista sobre "el orden de las operaciones" o "cómo se tratan los nulos".

**Ejemplos para presentar:**
1. *Falta de comillas/Uso de = con LIKE:* 
   `SELECT * FROM clientes WHERE nombre = %Juan%;` (Error)
2. *WHERE con agregados:* 
   `SELECT categoria, SUM(total) FROM ventas WHERE SUM(total) > 1000 GROUP BY categoria;` (Error)
3. *Uso incorrecto de NULL:* 
   `SELECT * FROM inventario WHERE stock = NULL;` (Error)

### Actividad 2: Demostración: SQL en el Sector Salud - 25 min
**Contexto:** Base de datos de un hospital.
**Pregunta:** "¿Cuántas consultas de urgencias tuvimos en 2023 por encima del promedio?"
**Ejecución:** Construir bloque a bloque: `SELECT` -> `WHERE` (año 2023) -> `GROUP BY` -> Subconsulta para el promedio. Mostrar cómo un solo cambio en el filtro altera radicalmente el resultado.

### Actividad 3: Laboratorio de Consultas de Negocio - 35 min
**Contexto:** Se divide a la clase en grupos de 3-4 personas.
**Problema:** "Encuentra al cliente que más ha gastado, pero ignora los pedidos cancelados y maneja los valores nulos en el nombre".
**Dinámica:** Cada grupo escribe la consulta en un documento compartido. Al final, un representante explica la lógica.

---

## 4. Sandbox SQL (Datos para Pruebas en Clase)

Ejecuta este script en tu entorno PostgreSQL antes de la clase para tener los datos necesarios para las actividades.

```sql
-- ==========================================
-- SANDBOX SQL: CREACIÓN Y POBLACIÓN DE TABLAS
-- ==========================================

-- 1. TABLA PARA SECTOR SALUD (Demostración)
CREATE TABLE urgencias_hospital (
    id SERIAL PRIMARY KEY,
    hospital VARCHAR(100),
    tipo_urgencia VARCHAR(50),
    anio INT,
    cantidad_pacientes INT
);

INSERT INTO urgencias_hospital (hospital, tipo_urgencia, anio, cantidad_pacientes) VALUES
('Son Espases', 'Traumatología', 2023, 1500),
('Son Espases', 'Pediatría', 2023, 800),
('Son Espases', 'Cardiología', 2023, 1200),
('Son Espases', 'Traumatología', 2022, 1400),
('Son Espases', 'Neurología', 2023, 400);


-- 2. TABLAS PARA E-COMMERCE (Laboratorio de Negocio)
CREATE TABLE clientes_ecommerce (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) -- Puede ser NULL
);

CREATE TABLE pedidos_ecommerce (
    id SERIAL PRIMARY KEY,
    cliente_id INT,
    total NUMERIC(10,2),
    estado VARCHAR(20)
);

INSERT INTO clientes_ecommerce (nombre) VALUES
('Ana Perez'),
(NULL),
('Carlos Gomez'),
('Maria Lopez');

INSERT INTO pedidos_ecommerce (cliente_id, total, estado) VALUES
(1, 150.00, 'Completado'),
(1, 250.00, 'Completado'),
(2, 500.00, 'Completado'), -- Cliente sin nombre
(2, 100.00, 'Cancelado'),
(3, 1200.00, 'Completado'),
(4, 50.00, 'Completado'),
(4, 3000.00, 'Cancelado'); -- Gasto alto pero cancelado


-- 3. TABLA PARA INVENTARIO (Ejemplos rápidos COALESCE)
CREATE TABLE inventario_stock (
    id SERIAL PRIMARY KEY,
    producto VARCHAR(100),
    stock_disponible INT -- Puede ser NULL si no hay registro
);

INSERT INTO inventario_stock (producto, stock_disponible) VALUES
('Monitor 24"', 15),
('Teclado Inalámbrico', NULL),
('Ratón Óptico', 0),
('Cable HDMI', NULL);

```

### Soluciones 

**Solución al Laboratorio de Negocio (E-commerce):**

```sql
SELECT 
    COALESCE(c.nombre, 'Cliente Anónimo') AS cliente,
    SUM(p.total) AS total_gastado
FROM pedidos_ecommerce p
JOIN clientes_ecommerce c ON p.cliente_id = c.id
WHERE p.estado != 'Cancelado'
GROUP BY c.nombre
ORDER BY total_gastado DESC
LIMIT 1;

```

**Solución Rápida COALESCE (Inventario):**

```sql
SELECT 
    producto,
    COALESCE(stock_disponible, 0) AS stock_real
FROM inventario_stock;

```
