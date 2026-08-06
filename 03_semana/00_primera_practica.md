# Limpieza de Datos de Inventario

## Contexto
En este ejercicio, actuamos como analistas para una empresa de retail que tiene datos incompletos en su inventario. El objetivo es limpiar los resultados mediante consultas SQL, aplicando especialmente la gestión de valores nulos (NULL).

## Datos de la Tabla
Trabajaremos con la tabla `productos`, la cual contiene las siguientes columnas:

| Columna | Tipo de Dato | Detalle |
| :--- | :--- | :--- |
| `nombre` | Texto | Obligatorio |
| `precio_lista` | Numérico | Puede ser NULL |
| `descuento_promocional` | Numérico | Puede ser NULL |
| `categoria` | Texto | Puede ser NULL |


```sql
-- ==========================================
-- Script de configuración para Práctica de Inventario
-- ==========================================

-- 1. Creación de la tabla 'productos'
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    precio_lista NUMERIC(10, 2),
    descuento_promocional NUMERIC(10, 2),
    categoria VARCHAR(100)
);

-- 2. Inserción de datos de prueba (Mock Data)
-- Estos datos están diseñados para cubrir todos los casos propuestos en el ejercicio (Nulos en distintas columnas)
INSERT INTO productos (nombre, precio_lista, descuento_promocional, categoria) VALUES
-- Caso 1: Producto completo con todos los datos
('Laptop Gamer X', 1500.00, 150.00, 'Electrónica'),

-- Caso 2: Producto sin descuento (descuento_promocional IS NULL) -> Para probar el Ejercicio 4
('Silla de Oficina Ergonómica', 120.00, NULL, 'Muebles'),

-- Caso 3: Producto sin categoría (categoria IS NULL) -> Para probar el Ejercicio 1 y 3
('Teclado Mecánico RGB', 85.00, 5.00, NULL),

-- Caso 4: Producto sin precio de lista (precio_lista IS NULL) -> Para probar el Ejercicio 2
('Auriculares Bluetooth', NULL, 10.00, 'Accesorios'),

-- Caso 5: Producto extremo con múltiples valores nulos -> Para probar la robustez de las consultas
('Mousepad XL', NULL, NULL, NULL),

-- Caso 6: Otro producto sin categoría y sin descuento
('Soporte para Monitor', 45.00, NULL, NULL);
```


## Consignas y Soluciones SQL

### 1. Identificar Huecos
**Consigna:** Escribe una consulta que devuelva todos los productos que **no tienen una categoría asignada**.

**Solución SQL:**
```sql
SELECT *
FROM productos
WHERE categoria IS NULL;

```

### 2. Reporte de Precios para el Cliente

**Consigna:** Crea un listado que muestre el nombre del producto y el precio. Si el `precio_lista` es NULL, debe mostrar `0`. Llama a esta columna `precio_final`.

**Solución SQL:**

```sql
SELECT 
    nombre,
    COALESCE(precio_lista, 0) AS precio_final
FROM productos;

```

### 3. Limpieza de Categorías

**Consigna:** Crea una consulta que muestre el nombre del producto y su categoría. Si la categoría es NULL, debe mostrar el texto `'Sin Categorizar'`.

**Solución SQL:**

```sql
SELECT 
    nombre,
    COALESCE(categoria, 'Sin Categorizar') AS categoria
FROM productos;

```

### 4. Cálculo de Descuentos (Reto)

**Consigna:** Crea una consulta que calcule el precio tras aplicar el descuento (`precio_lista - descuento_promocional`). ¡Cuidado! Si el descuento es NULL, la resta fallará (dará NULL). Usa `COALESCE` para que, si el descuento es NULL, sea tratado como `0`.

**Solución SQL:**

```sql
SELECT 
    nombre,
    precio_lista,
    descuento_promocional,
    (precio_lista - COALESCE(descuento_promocional, 0)) AS precio_con_descuento
FROM productos;

```

> **Nota de robustez:** Si se asume que el `precio_lista` también puede ser `NULL` al momento de hacer el cálculo de la resta, una solución aún más blindada sería:
> `(COALESCE(precio_lista, 0) - COALESCE(descuento_promocional, 0)) AS precio_con_descuento`
> """
