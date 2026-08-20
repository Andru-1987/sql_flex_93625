# Resumen del Módulo 5: SQL Avanzado para Análisis de Datos

## 1. Estructura Modular y Limpieza: CTEs (Common Table Expressions)

Cuando un análisis de negocio requiere múltiples pasos intermedios, las subconsultas tradicionales tienden a anidarse de forma desordenada, lo que vuelve al código difícil de leer y mantener.

**¿Qué es una CTE?**
Es una expresión de tabla común declarada mediante la cláusula `WITH`. Actúa como una "tabla temporal virtual" o "nota adhesiva" en memoria a la que puedes hacerle consultas inmediatamente después.

**La Analogía de la Cocina (Mise en Place)**
Imagina que eres un chef. En lugar de picar y cocinar todo de forma caótica al mismo tiempo, organizas tus ingredientes limpios y picados en cuencos lógicos independientes en tu mesa de trabajo antes de encender el fuego. Las CTEs preparan y filtran los datos por pasos antes de la consulta principal final.

**Ventajas Clave:**

* **Lectura Natural:** A diferencia de las subconsultas anidadas que se leen de adentro hacia afuera, las CTEs se leen de manera intuitiva de arriba hacia abajo.
* **Modularidad:** Divide un gran problema de negocio en pequeños fragmentos lógicos de código independientes.
* **Rendimiento:** Permiten filtrar y pre-agregar datos dentro de la propia CTE para que la consulta final procese un volumen de información mucho menor y más rápido.

**Errores Comunes de Sintaxis al usar CTEs:**

1. **Olvidar alias en columnas calculadas:** Si calculas una agregación (como `SUM(monto)`) dentro de la CTE y no le pones un alias (`AS total_ventas`), no podrás llamar a esa columna en tu `SELECT` final.
2. **Cerrar mal los paréntesis:** La definición de la CTE debe ir estrictamente encerrada entre paréntesis antes de abrir el `SELECT` principal.
3. **Duplicar la palabra clave `WITH`:** Si necesitas definir varias CTEs para la misma consulta, solo debes usar `WITH` una vez al principio. Las siguientes CTEs se declaran separadas simplemente por comas.

---

## 2. El Superpoder del Analista: Funciones de Ventana (Window Functions)

En el análisis de datos tradicional, las funciones agregadas (como `SUM` o `AVG`) colapsan o "aplanan" las filas, perdiendo el detalle de cada registro individual en el reporte final. Las Funciones de Ventana resuelven esto al realizar cálculos complejos sobre un conjunto de filas relacionadas sin colapsar la tabla original.

### A. Funciones de Clasificación o Ranking

Cuando existen empates en métricas de negocio, PostgreSQL ofrece tres funciones específicas con comportamientos diferentes:

* **`ROW_NUMBER()`:** Asigna un número secuencial único e incremental a cada fila (1, 2, 3, 4) sin importar si hay empates.
* **`RANK()`:** Permite empates asignando el mismo número de puesto, pero salta las posiciones posteriores correspondientes al número de empatados (Ejemplo: 1, 1, 3).
* **`DENSE_RANK()`:** Permite empates asignando el mismo número de puesto, pero no salta posiciones secuenciales en la clasificación (Ejemplo: 1, 1, 2). Es la opción preferible cuando buscas "los dos niveles de precios más altos" o jerarquías continuas.

**Script de Prueba Comparativo**

```sql
-- 1. Creamos la tabla de prueba para las ventas
CREATE TABLE ventas_mensuales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    monto_vendido INT
);

-- 2. Insertamos los datos (notamos el empate en 950)
INSERT INTO ventas_mensuales (nombre, monto_vendido)
VALUES 
    ('Ana', 1000),
    ('Carlos', 950),
    ('Beatriz', 950),
    ('David', 800);

-- 3. Ejecutamos la consulta comparativa
SELECT 
    nombre,
    monto_vendido,
    ROW_NUMBER() OVER(ORDER BY monto_vendido DESC) AS puesto_row_number,
    RANK() OVER(ORDER BY monto_vendido DESC) AS puesto_rank,
    DENSE_RANK() OVER(ORDER BY monto_vendido DESC) AS puesto_dense_rank
FROM ventas_mensuales;

```

**Explicación del Resultado:**

1. **`puesto_row_number`:** Verás 1, 2, 3, 4. No le importan los empates; simplemente cuenta las filas.
2. **`puesto_rank`:** Verás 1, 2, 2, 4. Reconoce el empate dándoles el puesto 2 a Carlos y Beatriz, pero salta el puesto 3, mandando a David al 4.
3. **`puesto_dense_rank`:** Verás 1, 2, 2, 3. Reconoce el empate y mantiene la secuencia compacta, dejando a David en el puesto 3.

### B. El Operador PARTITION BY

Es la cláusula que le indica a la función de ventana dónde debe reiniciar su contador.

* *Ejemplo:* Si calculas un ranking de películas más vistas particionado por género (`PARTITION BY genero`), el contador se reiniciará en 1 cada vez que cambie el género, permitiendo generar rankings segmentados en un único reporte.

### C. Segmentación de Grupos con NTILE(n)

`NTILE(n)` es una función de ventana que actúa como una forma de cortar un pastel en "n" rebanadas iguales. Toma el listado ordenado y lo divide en una cantidad específica de grupos, asignándole a cada fila el número del grupo al que pertenece.

| Función | ¿Qué hace? | Manejo de grupos irregulares | Casos de uso comunes |
| --- | --- | --- | --- |
| **`NTILE(n)`** | Divide las filas en "n" grupos lo más equitativos posible y les asigna un número de grupo. | Pone las filas sobrantes en los primeros grupos (Ej: 6 filas en 4 grupos = 2, 2, 1, 1). | Calcular Cuartiles `NTILE(4)`, Deciles `NTILE(10)`. Ideal para "Top 25% de clientes". |

**Script de Prueba NTILE**

```sql
CREATE TABLE ranking_ventas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    monto_vendido INT
);

INSERT INTO ranking_ventas (nombre, monto_vendido)
VALUES 
    ('Ana', 1200),
    ('Beatriz', 1050),
    ('Carlos', 900),
    ('David', 800),
    ('Elena', 650),
    ('Fernando', 500);

SELECT 
    nombre,
    monto_vendido,
    NTILE(2) OVER(ORDER BY monto_vendido DESC) AS grupo_mitades,
    NTILE(3) OVER(ORDER BY monto_vendido DESC) AS grupo_tercios,
    NTILE(4) OVER(ORDER BY monto_vendido DESC) AS grupo_cuartiles
FROM ranking_ventas;

```

*Detalle clave:* Al usar `NTILE(4)` con 6 registros, el resto es 2. PostgreSQL asigna esas 2 personas sobrantes a los primeros dos grupos (Grupos 1 y 2 tendrán 2 personas; Grupos 3 y 4 tendrán 1 persona).

### D. Totales Acumulados (Running Totals)

Permiten ver tendencias progresivas a lo largo del tiempo utilizando la estructura `SUM(monto) OVER (ORDER BY fecha)`.

* *Trampa clásica:* Si olvidas la cláusula `ORDER BY` dentro del `OVER`, PostgreSQL devolverá la suma total global repetida en cada fila, en lugar del acumulado progresivo línea por línea.

### E. Análisis de Tendencias Temporales: LAG() y LEAD()

* **`LAG()` (El espejo retrovisor):** Permite acceder a los datos de la fila anterior. Vital para comparar la métrica actual contra el mes anterior.
* **`LEAD()` (Los prismáticos):** Permite acceder a los datos de la fila siguiente. Ideal para calcular el tiempo transcurrido entre compras sucesivas.

| Función | ¿Qué hace? | ¿Qué pasa en los extremos? | Casos de uso comunes |
| --- | --- | --- | --- |
| **`LAG()`** | Trae el valor de la fila anterior. | En la primera fila devuelve `NULL`. | Comparar ventas mensuales vs. mes anterior. |
| **`LEAD()`** | Trae el valor de la fila siguiente. | En la última fila devuelve `NULL`. | Predecir próxima compra o días hasta el próximo evento. |

**Script de Prueba LAG y LEAD**

```sql
CREATE TABLE historial_ingresos (
    id SERIAL PRIMARY KEY,
    mes VARCHAR(20),
    orden_mes INT,
    ingresos INT
);

INSERT INTO historial_ingresos (mes, orden_mes, ingresos)
VALUES 
    ('Enero', 1, 5000),
    ('Febrero', 2, 5500),
    ('Marzo', 3, 5200),
    ('Abril', 4, 6000);

SELECT 
    mes,
    ingresos AS ingresos_actuales,
    LAG(ingresos) OVER(ORDER BY orden_mes) AS mes_anterior,
    LEAD(ingresos) OVER(ORDER BY orden_mes) AS mes_siguiente
FROM historial_ingresos;

```

---

## 3. Manejo Avanzado de Fechas y Lógica Condicional

Un analista avanzado debe procesar el tiempo e inyectar lógica de negocio dinámica en sus reportes.

### A. Extracción y Redondeo de Series Temporales

* **`EXTRACT(componente FROM fecha)`:** Aísla partes numéricas (mes, año, día). *Precaución:* Extraer solo el mes puede mezclar datos de distintos años.
* **`DATE_TRUNC('unidad', fecha)`:** Trunca una fecha al inicio de su período (ej. transforma fechas de marzo en `2024-03-01`). Es la mejor herramienta para agrupar ventas mensuales sin perder la dimensión del año.
* **Tipo de dato `INTERVAL`:** Permite cálculos aritméticos de fechas nativos y legibles (Ej: restar `INTERVAL '30 days'` a la fecha actual).

### B. Lógica Condicional: CASE WHEN

Estructura fundamental para categorizar y segmentar datos dinámicamente según reglas de negocio.

```sql
CASE 
    WHEN dias_demora <= 2 THEN 'Excelente'
    WHEN dias_demora BETWEEN 3 AND 5 THEN 'Aceptable'
    ELSE 'Atrasado'
END AS estado_cumplimiento

```

**Reglas de Oro con CASE WHEN:**

1. **Regla de especificidad:** Se evalúa de arriba hacia abajo y se detiene en la primera condición verdadera. Programa siempre desde lo más específico hacia lo más general.
2. **No olvidar el `ELSE`:** Si lo omites y ninguna condición se cumple, la consulta devuelve `NULL`, lo que puede sesgar tus reportes.
3. **Consistencia de tipos de datos:** Todos los valores retornados (en los `THEN` y en el `ELSE`) deben ser del mismo tipo de dato. Mezclar texto con números generará un error de sintaxis.