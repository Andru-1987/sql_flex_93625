# Módulo 4 - Relaciones, JOINS y Agrupaciones Avanzadas

Este documento consolida los conceptos fundamentales sobre la integración de datos provenientes de múltiples fuentes y la aplicación de agrupaciones complejas de manera eficiente en PostgreSQL.

---

## 1. Fundamentos de Relaciones y Estructura de JOINS

Las bases de datos relacionales estructuran la información en tablas lógicas (normalización) con el objetivo de mitigar la redundancia y garantizar la consistencia de los datos. Las relaciones físicas se establecen mediante la conexión de la **Clave Primaria (Primary Key - PK)** de una entidad principal con la **Clave Foránea (Foreign Key - FK)** de una entidad dependiente.

Un **JOIN** es la instrucción algorítmica que indica a PostgreSQL cómo combinar horizontalmente las filas de múltiples tablas basándose en un identificador común.

### Consideraciones Sintácticas y Buenas Prácticas:

* **Cláusula `ON`:** Es un requisito estricto para definir el criterio de emparejamiento. Su omisión genera un **Producto Cartesiano** (Cross Join), el cual combina cada registro de la primera tabla con la totalidad de la segunda, resultando en un consumo ineficiente de recursos y la alteración de los resultados.
* **Uso de Alias:** Consiste en la asignación de referencias abreviadas a las tablas (por ejemplo, `clientes AS c`, `pedidos AS p`). Su implementación es estándar en la industria para mantener el código legible y conciso.
* **Ambigüedad de Identificadores:** Cuando dos tablas comparten nombres de columnas (como `id` o `nombre`), es mandatorio especificar el origen utilizando la notación de punto con su respectivo alias (`c.id` o `p.id`) para evitar errores de compilación por ambigüedad.

---

## 2. Clasificación de JOINS (Operaciones de Conjuntos)

La interacción entre tablas puede conceptualizarse mediante la teoría de conjuntos:

### INNER JOIN: Intersección Estricta

* **Definición:** Retorna exclusivamente las filas que poseen una coincidencia exacta en ambas tablas evaluadas.
* **Aplicación Práctica:** Ideal para reportes que requieren relaciones bidireccionales confirmadas (por ejemplo, clientes que poseen un historial de transacciones comprobable).

### LEFT JOIN: Inclusión Izquierda

* **Definición:** Conserva la totalidad de los registros de la tabla declarada a la izquierda (inmediatamente después de la cláusula `FROM`), independientemente de si existe coincidencia en la tabla de la derecha. Las ausencias de correspondencia se completan con valores `NULL`.
* **Aplicación Práctica:** Es el método estándar para auditorías de integridad de datos y detección de registros huérfanos (por ejemplo, identificar usuarios registrados sin actividad comercial filtrando mediante `WHERE tabla_derecha.id IS NULL`).

### RIGHT JOIN: Inclusión Derecha

* **Definición:** Mantiene todos los registros de la tabla declarada a la derecha, rellenando con `NULL` las columnas de la tabla izquierda donde no haya coincidencia.
* **Consideración de Diseño:** Operativamente, cualquier `RIGHT JOIN` puede reescribirse como un `LEFT JOIN` invirtiendo el orden de las entidades. Por convención y legibilidad del código (lectura occidental de izquierda a derecha), se prefiere estandarizar el uso de `LEFT JOIN`.

### FULL OUTER JOIN: Inclusión Total

* **Definición:** Representa la unión completa de los conjuntos. Devuelve todos los registros de ambas tablas; donde existe relación, los datos se emparejan, y donde no, los espacios se completan con `NULL`.

---

## 3. Combinación Múltiple de Entidades

La resolución de lógicas de negocio complejas frecuentemente requiere la unificación de múltiples tablas. SQL procesa estas uniones de manera secuencial:

1. El motor de base de datos evalúa y une la **Tabla A con la Tabla B**.
2. El set de datos temporal resultante se une posteriormente con la **Tabla C**, repitiendo el proceso según sea necesario.

**Flujo Relacional Estándar:** `Clientes (c) -> Pedidos (p) -> Detalle_Pedido (d) -> Productos (pr)`

---

## 4. Agrupaciones de Datos (GROUP BY)

La instrucción `GROUP BY` consolida múltiples filas que comparten atributos idénticos en un único registro resumen, permitiendo el cálculo de métricas agregadas.

* **Principio de Agrupación:** Consiste en segmentar un volumen masivo de datos transaccionales mediante categorías específicas. Posteriormente, se aplican **funciones de agregación** (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) para procesar las métricas de cada segmento.
* **Regla Estructural Inquebrantable:** Toda columna declarada en la cláusula `SELECT` que no esté encapsulada dentro de una función de agregación, **debe figurar de manera obligatoria** en la cláusula `GROUP BY`. El incumplimiento de esta norma genera una falla de ejecución inmediata.
* **Dimensionalidad Múltiple:** Es sintácticamente válido establecer agrupaciones por múltiples dimensiones jerárquicas en una sola consulta (por ejemplo, `GROUP BY codigo_categoria, marca_articulo`).

---

## 5. Criterios de Filtrado: WHERE vs. HAVING

A pesar de que ambas instrucciones restringen resultados, operan en fases distintas del procesamiento del motor SQL:

* **WHERE (Filtrado a Nivel de Fila):** Evalúa y descarta registros individuales **antes** de que ocurra cualquier agrupación estructural. Por definición lógica, **no permite la inclusión de funciones de agregación**.
* **HAVING (Filtrado a Nivel de Grupo):** Interviene **después** de que los datos han sido agrupados y las funciones matemáticas han sido calculadas. Su propósito exclusivo es condicionar métricas ya procesadas (por ejemplo, `HAVING SUM(ventas) > 1000`).

---

## 6. Arquitectura de Ejecución Lógica de Consultas

PostgreSQL procesa las instrucciones siguiendo una jerarquía estricta, independiente del orden de escritura. Comprender este ciclo de vida es fundamental para la depuración de consultas:

1. **FROM / JOIN:** Identificación de las fuentes de datos y procesamiento de uniones horizontales.
2. **WHERE:** Aplicación de filtros iniciales a nivel de fila.
3. **GROUP BY:** Segmentación de los registros resultantes en agrupaciones lógicas.
4. **HAVING:** Aplicación de restricciones sobre las métricas de los grupos creados.
5. **SELECT:** Extracción de las columnas solicitadas y proyección final de los datos.
6. **ORDER BY:** Organización y ordenamiento de la salida final.

*Implicación Técnica:* Debido a que `HAVING` se ejecuta internamente antes que `SELECT`, no es posible utilizar en el `HAVING` los alias definidos en la selección; se debe replicar la expresión completa. Asimismo, la cláusula `GROUP BY` no asegura un ordenamiento determinista; para garantizar la presentación visual de los datos, el uso de `ORDER BY` es imperativo.

---

## 7. Operadores de Conjuntos (Unión Vertical)

A diferencia de los JOINS, que expanden el modelo de datos horizontalmente (añadiendo atributos), los operadores de conjuntos combinan estructuras verticalmente (añadiendo registros).

* **`UNION`:** Fusiona conjuntos de resultados y ejecuta una verificación interna para **eliminar registros duplicados**. Esta operación es intensiva a nivel computacional debido a la evaluación comparativa.
* **`UNION ALL`:** Consolida los resultados manteniendo la integridad total de los registros, incluidos los duplicados. Es computacionalmente más eficiente al omitir el paso de validación.

### Reglas Estructurales para Operadores de Conjunto:

1. Las consultas a unir deben proyectar **exactamente la misma cantidad de columnas**.
2. El **tipo de dato** de las columnas que comparten la misma posición debe ser compatible.
3. Los encabezados de las columnas del resultado final son heredados automáticamente de la primera consulta.
4. La instrucción `ORDER BY` debe posicionarse exclusivamente al final de la última consulta para ordenar el set de datos ya unificado.