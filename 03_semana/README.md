# Consultas Esenciales y Filtrado de Datos

## Pasos para abordar estos temas

Para abordar este módulo con éxito sin abrumarte, te recomendamos seguir esta ruta de aprendizaje en 5 pasos:

* **Paso 1: Entiende la estructura (SELECT / FROM).** Domina primero cómo pedir columnas completas de una tabla. No te preocupes por filtrar todavía; acostúmbrate a la sintaxis y a escribir las palabras clave en mayúsculas.
* **Paso 2: Domina el filtro (WHERE & LIKE).** Aprende a "recortar" filas. Practica con operadores de comparación y lógicos, y experimenta con la búsqueda de texto parcial usando patrones.
* **Paso 3: Controla la presentación (ORDER BY & LIMIT).** Descubre cómo dar formato visual a tus resultados, ordenándolos y limitando la cantidad de filas que recibes (útil para rankings o paginación).
* **Paso 4: Aprende a resumir (Funciones de Agregación).** Cambia la perspectiva: pasa de ver filas individuales a calcular estadísticas grupales (totales, promedios, máximos y mínimos).
* **Paso 5: Resuelve el misterio del vacío (IS NULL & COALESCE).** Entiende qué es el valor NULL y cómo tratarlo para que tus reportes no contengan errores matemáticos ni espacios feos en blanco.

## Resumen de Contenidos por Unidad

### Unidad 1: La Sentencia SELECT (Extracción Básica)
* La sentencia SELECT no altera los datos en el disco duro; funciona únicamente como un filtro de visualización para traer la información al frente.
* **Sintaxis Mínima:** Requiere SELECT (qué columnas quieres ver) y FROM (de qué tabla provienen).
* **Selección Múltiple:** Se listan las columnas deseadas separadas por comas (ej. `SELECT nombre, precio FROM productos;`). ¡Evita poner una coma después de la última columna o PostgreSQL dará un error de sintaxis!
* **El Comodín Asterisco (*):** `SELECT * FROM tabla;` devuelve absolutamente todas las columnas y filas. Es útil para explorar tablas nuevas, pero es una mala práctica en producción y reportes automáticos porque consume ancho de banda innecesario y puede romper tus consultas si la estructura de la tabla cambia en el futuro.
* **La Analogía de la Cocina:** Imagina que eres un chef. La base de datos es tu despensa. Ir por un saco de patatas a la despensa equivale al FROM. Quitarle los "ojos" a las patatas para usarlos en tu plato equivale al SELECT. No puedes pelar las patatas sin haber traído primero el saco.

### Unidad 2: Filtrado Avanzado (La Cláusula WHERE)
* En bases de datos reales con millones de filas, no quieres ver todo; necesitas extraer subconjuntos específicos mediante reglas de negocio.
* **Operadores de Comparación:** Permiten filtrar valores exactos o rangos (=, >, <, >=, <=, !=).
* **Operadores Lógicos:**
  * **AND (Filtro exclusivo):** Ambas condiciones deben ser verdaderas simultáneamente.
  * **OR (Filtro inclusivo):** Basta con que una condición sea verdadera.
  * **NOT (Exclusión):** Invierte el resultado de la condición.
* **El Poder de los Paréntesis:** El operador AND tiene prioridad (fuerza) sobre el OR. Si quieres que el OR se evalúe primero, debes agruparlo entre paréntesis (ej. `WHERE (categoria = 'Ropa' OR categoria = 'Calzado') AND precio > 50`).
* **Patrones de Texto (LIKE e ILIKE):** Permiten buscar palabras incompletas usando comodines.
  * **%:** Representa cualquier número de caracteres (cero o más). (Ej. `'%gmail.com'` para correos o `'A%'` para textos que inicien con A).
  * **_:** Representa exactamente un único carácter.
  * **LIKE vs ILIKE:** LIKE distingue estrictamente entre mayúsculas y minúsculas; ILIKE las ignora (es insensible al caso en PostgreSQL).

### Unidad 3: Presentación de Resultados (ORDER BY, LIMIT y OFFSET)
* **ORDER BY:** Organiza los resultados en base a una o más columnas. Se puede ordenar de forma ascendente (ASC, por defecto de menor a mayor/A-Z) o descendente (DESC, de mayor a menor/Z-A).
* **LIMIT:** Restringe el número máximo de filas devueltas por la consulta (ideal para obtener "Top 5" o previsualizaciones rápidas).
* **OFFSET:** Salta un número determinado de filas antes de empezar a mostrar los resultados (es la base para programar la paginación de un sitio web).
* **La Regla de Oro (Estabilidad):** Nunca uses LIMIT u OFFSET sin un ORDER BY. Las bases de datos relacionales no garantizan un orden interno fijo; si no defines un orden explícito, un registro que hoy aparece en la página 1 mañana podría salir en otra página diferente.

### Unidad 4: Funciones de Agregación (Resumir Datos)
* Las funciones de agregación toman múltiples filas de una columna y las reducen a un único resultado matemático descriptivo.
* **COUNT:** Cuenta filas o valores. `COUNT(*)` cuenta todas las filas de la tabla (incluyendo las vacías). `COUNT(columna)` cuenta únicamente las filas donde esa columna tiene un valor (ignora los NULL).
* **SUM y AVG:** Calculan la suma total y el promedio de una columna numérica, respectivamente. Consejo profesional: PostgreSQL suele devolver muchos decimales en el promedio, por lo que se recomienda envolver la función en `ROUND(AVG(columna), 2)` para limitar a dos decimales.
* **MIN y MAX:** Devuelven el valor mínimo y máximo. Funcionan tanto con números, como con fechas (fecha más antigua y más reciente) o cadenas de texto (orden alfabético).
* **Nota vital:** Todas las funciones de agregación (excepto `COUNT(*)`) ignoran automáticamente los valores nulos (NULL).

### Unidad 5: El Tratamiento de NULLs (IS NULL y COALESCE)
* **¿Qué es NULL?:** Representa la ausencia física de un valor; es un dato "desconocido" o "no disponible". No es un cero ni un espacio de texto vacío.
* **La Analogía de los Sobres:** Imagina tres sobres en una mesa. Uno tiene un billete de $0 (sabes lo que hay: nada). El segundo sobre está abierto pero no tiene nada (un texto vacío ''). El tercer sobre está cerrado y sellado: no sabes qué hay dentro. Este último es un valor NULL. Por ello, no puedes compararlo con otros de forma tradicional.
* **El Gran Error de Comparación:** Hacer `WHERE columna = NULL` siempre dará falso porque no puedes comparar un valor desconocido con otro. Para filtrar registros ausentes debes usar estrictamente `IS NULL` o `IS NOT NULL`.
* **La Función COALESCE:** Evalúa una lista de argumentos de izquierda a derecha y devuelve el primer valor que no sea nulo. Es sumamente útil para dar un valor de reemplazo amigable en reportes (ej. `COALESCE(telefono, 'Sin teléfono')` o `COALESCE(descuento, 0)`).

## Resumen de Puntos Principales (La "Caja de Herramientas" Esencial)

Para consolidar tu perfil técnico, grábate estas tres lecciones fundamentales del Módulo 3:

### 1. El Orden de Escritura vs. El Orden de Ejecución Lógica
Este es el concepto más importante para evitar frustraciones. SQL se escribe de una forma, pero PostgreSQL lo lee y lo ejecuta de otra:

| Orden de Escritura (Cómo lo codificas) | Orden de Ejecución Lógica (Cómo lo lee el motor) |
| :--- | :--- |
| 1. SELECT | 1. FROM (Busca la tabla en disco) |
| 2. FROM | 2. WHERE (Descarta las filas que no cumplen) |
| 3. WHERE | 3. SELECT (Recorta las columnas pedidas) |
| 4. ORDER BY | 4. ORDER BY (Ordena visualmente las columnas) |
| 5. LIMIT / OFFSET | 5. LIMIT / OFFSET (Recorta el bloque final) |

¿Por qué importa esto? Por ejemplo, si creas un apodo (alias) para una columna en el SELECT, no puedes usar ese alias en el WHERE, ya que el motor ejecuta el WHERE antes de siquiera saber cómo decidiste renombrar la columna en el SELECT.

### 2. Convenciones de Estilo Profesionales
* Escribe siempre las palabras clave reservadas de SQL en MAYÚSCULAS (SELECT, FROM, WHERE) y las columnas/tablas en minúsculas. Esto hace tu código legible y estándar en la industria de Data Science.
* Termina siempre tus sentencias SQL con un punto y coma (;).

### 3. Evita las "Trampas" Clásicas del Principiante
* **Confusión AND / OR:** En el lenguaje cotidiano decimos "Quiero ver los clientes de Madrid y Barcelona". En SQL, si usas `WHERE ciudad = 'Madrid' AND ciudad = 'Barcelona'`, obtendrás cero resultados porque una sola fila no puede tener dos ciudades distintas a la vez. La consulta correcta requiere un OR.
* **Seleccionar columnas extra con Agregación:** Si haces `SELECT nombre, COUNT(*) FROM empleados;` obtendrás un error. Una función de agregación resume los datos en una sola fila, pero la columna nombre tiene múltiples filas independientes. No puedes mostrarlas juntas a menos que uses agrupaciones (GROUP BY), que verás en el siguiente módulo.