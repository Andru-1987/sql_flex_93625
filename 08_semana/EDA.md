# EDA

Un **EDA** (por sus siglas en inglés, *Exploratory Data Analysis*, o **Análisis Exploratorio de Datos**) es la primera fase crítica en cualquier proyecto de análisis o ciencia de datos. Consiste en examinar, investigar y "conocer" a fondo un conjunto de datos antes de intentar responder preguntas complejas o crear modelos predictivos.

Piensa en el EDA como la inspección que hace un chef a sus ingredientes antes de empezar a cocinar: revisa qué tiene disponible, si algo está en mal estado (datos corruptos o faltantes) y en qué cantidades.

### ¿Cuáles son los objetivos principales de un EDA?

* **Entender la estructura:** Saber qué variables (columnas) existen y qué representa cada una.
* **Detectar anomalías y errores:** Encontrar datos faltantes (nulos) o valores extremos que no tienen sentido (outliers), como un cliente con edad de "250 años".
* **Descubrir patrones subyacentes:** Identificar tendencias iniciales (ej. "las ventas siempre suben en diciembre").
* **Validar hipótesis del negocio:** Confirmar si lo que el equipo directivo cree que pasa realmente está respaldado por los datos.

---

### ¿Qué es lo que se suele hacer paso a paso en un EDA?

Aunque las herramientas cambien (puede hacerse en SQL, Python con Pandas, R, o Excel), los pasos conceptuales son casi siempre los mismos:

**1. Inspección de la estructura (El primer vistazo)**

* Revisar el tamaño del dataset (cantidad de filas y columnas).
* Identificar los tipos de datos: confirmar que las fechas sean tratadas como fechas (`DATE`) y no como texto, o que los precios sean numéricos (`NUMERIC`).

**2. Identificación y tratamiento de la "suciedad" (Data Cleaning)**

* Contar cuántos valores nulos o vacíos hay por columna.
* Decidir una estrategia para esos nulos: ¿Los ignoramos? ¿Los rellenamos con un valor por defecto (usando funciones como `COALESCE` en SQL)?
* Buscar y eliminar filas duplicadas.

**3. Estadística Descriptiva (Resumen numérico)**

* Calcular métricas básicas para variables numéricas: promedio, mediana, valor máximo, valor mínimo y desviación estándar.
* Calcular frecuencias para variables categóricas (texto): por ejemplo, contar cuántos clientes hay por cada país o ciudad.

**4. Análisis Univariado (Variable por variable)**

* Estudiar cómo se distribuye una sola columna de forma aislada. ¿La mayoría de los pedidos son de poco valor o hay compras gigantes? Esto ayuda a encontrar los valores atípicos (outliers).

**5. Análisis Bivariado (Relaciones entre variables)**

* Cruzar dos o más columnas para entender cómo se afectan entre sí.
* ¿Los clientes que se registraron hace más de un año gastan más que los nuevos?
* ¿Existe correlación entre la cantidad de descuento aplicado y el volumen de unidades compradas? (En SQL, esto se logra agrupando datos con `GROUP BY` y uniendo tablas con `JOIN`).

El objetivo final de un EDA no es entregar un reporte definitivo, sino asegurarte de que los datos sean confiables y descubrir las historias ocultas que te guiarán en el resto de tu análisis.
