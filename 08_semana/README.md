# Analisis de Datos por medio de SQL

## Objetivo

Simular el flujo de trabajo integral de un analista de datos utilizando PostgreSQL. Esto abarca desde la preparación y limpieza de un dataset, hasta la ejecución de análisis exploratorio (EDA) y la interpretación de los hallazgos para la toma de decisiones estratégicas de negocio.

## Consigna

Desarrollar un repositorio en GitHub que contenga el análisis de un negocio de e-commerce (tablas `clientes`, `productos` y `pedidos`). El repositorio debe incluir estrictamente tres archivos:

1. `estructura.sql`: Scripts de definición de datos (DDL) y manipulación (DML) para inicializar el entorno.
2. `analisis.sql`: Consultas comentadas resolviendo preguntas de negocio.
3. `README.md`: Documentación enfocada en negocio, explicando problemas, hallazgos y conclusiones.

## Puntos importantes

* **Manejo de Nulos:** Es obligatorio el uso de `COALESCE` para gestionar valores nulos en columnas críticas (como descuentos o precios).
* **Tipado de Datos:** Asignar correctamente tipos como `DATE`, `NUMERIC`, `VARCHAR`.
* **Comentarios de Valor:** Los comentarios en el SQL deben explicar el *por qué* (contexto de negocio) y no el *qué* (sintaxis).
* **Interpretación:** El README debe traducir los resultados de SQL en conocimiento accionable para directivos.

## Explicacion de Negocio sobre el analisis 


# Análisis Exploratorio de Datos (EDA) - E-commerce

## Problema del Negocio
Nuestra empresa de e-commerce ha experimentado un crecimiento acelerado en los últimos meses, pero la directiva carece de visibilidad clara sobre los patrones de compra. El objetivo de este análisis es extraer información procesable de nuestra base de datos transaccional para:
1. Identificar a los clientes más valiosos (VIPs) para estrategias de retención.
2. Comprender la estacionalidad de nuestras ventas.
3. Optimizar la gestión de inventario detectando productos de baja rotación.
4. Identificar los productos líderes por segmento (categoría).

## Hallazgos Principales
Tras ejecutar el pipeline de análisis en PostgreSQL y realizar la limpieza de datos (gestionando transacciones con ausencia de datos en descuentos mediante `COALESCE`), se destacan los siguientes hallazgos:

* **Concentración de Ingresos:** Un segmento muy reducido de clientes (liderado por Lucía y Ana) concentra más del 60% de los ingresos totales. El ticket promedio de estos clientes se eleva sustancialmente al adquirir hardware de alto valor (Laptops).
* **Estacionalidad:** El mes de septiembre registró un pico anómalo de ingresos y volumen de transacciones, impulsado fuertemente por la venta en volumen de accesorios (Mouse) y múltiples unidades de hardware principal.
* **Baja Rotación en Mobiliario:** A pesar del auge del trabajo remoto, productos como el "Teclado Mecánico" y el "Escritorio Standing" presentan los niveles más bajos de venta en todo el catálogo.
* **Liderazgo por Categoría:** El "Monitor 27 pulgadas" lidera en retornos financieros en la categoría Electrónica tras la Laptop, superando a la venta en volumen de accesorios más económicos.

## Conclusiones para el Análisis y Próximos Pasos
1. **Programa de Lealtad Estratégico:** Lanzar un programa VIP focalizado en el Top 5 de clientes detectados, ofreciendo beneficios exclusivos. Perder a uno de estos clientes impactaría severamente la facturación.
2. **Campaña de Liquidación:** Sugerimos crear campañas de "Cross-selling" asociando los escritorios y teclados mecánicos (los menos vendidos) con la compra de Laptops o Monitores, ofreciendo un bundle con descuento para mover el inventario estancado.
3. **Optimización de Precios:** Revisar la política de descuentos. El uso intensivo de descuentos en transacciones de alto volumen durante septiembre incrementó las ventas, pero requiere un análisis de margen de beneficio para evaluar su sostenibilidad.
