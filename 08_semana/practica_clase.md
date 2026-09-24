**Practica adicional para la clase**
PostgreSQL enfocado en resolver problemas reales de negocio. Deberiamos estructurar un flujo de trabajo analítico, depurar consultas con errores intencionales (debugging), manejar valores nulos adecuadamente y optimizar el rendimiento de las consultas. Las actividades principales incluyen reparar un script roto, construir un dashboard para identificar a los mejores clientes, debatir sobre optimización con `EXPLAIN`, y aplicar técnicas de análisis de retención (churn) y segmentación de clientes.

---

## Objetivo

Aplicar los conocimientos teóricos de SQL en un escenario de análisis de datos en vivo, desarrollando la capacidad de depurar errores lógicos, optimizar consultas estructuradas y transformar datos crudos en respuestas concretas para la toma de decisiones de negocio.

## Consigna

Completar un flujo de trabajo analítico "end-to-end" durante la sesión mediante tres actividades principales:

1. **Cirugía de Consultas:** Identificar y corregir tres errores comunes en un código SQL provisto (JOIN mal definido, confusión entre WHERE/HAVING, y error de tipos).
2. **Dashboard Analítico:** Escribir desde cero una consulta para identificar a los 5 mejores clientes y su promedio de compra anual, gestionando los valores nulos con la función `COALESCE`.
3. **Optimización y Casos Prácticos:** Analizar planes de ejecución con `EXPLAIN ANALYZE` y resolver dos casos sugeridos: un análisis de bajas (Churn) y una segmentación dinámica de clientes.

## Puntos importantes

* **Filtros lógicos:** Comprender la diferencia estructural entre `WHERE` (filtra filas antes de agrupar) y `HAVING` (filtra resultados después de agrupar).
* **Gestión de Nulos:** Entender que `NULL` significa "desconocido", no cero. El uso de `COALESCE` es obligatorio para evitar errores matemáticos en sumas y promedios.
* **Rendimiento:** Utilizar `EXPLAIN ANALYZE` para diagnosticar cuellos de botella (ej. Sequential Scan vs. Index Scan).

---
# Validacion desde el lado de negocio

## Problema del negocio
La empresa necesita optimizar sus estrategias de marketing y retención. Actualmente, no hay visibilidad sobre quiénes son los clientes que generan el mayor volumen de ingresos a lo largo del tiempo, ni se tiene un registro claro de los usuarios que han dejado de interactuar con la plataforma (churn). Además, los reportes financieros previos presentaban errores de cálculo debido a registros de descuentos vacíos en la base de datos.

## Hallazgos
1. **Impacto de Datos Nulos:** Al auditar la tabla de órdenes, se descubrió que un alto porcentaje de transacciones no poseía un valor de descuento asignado (NULL en lugar de 0). Esto estaba sesgando a la baja los reportes de promedios de ventas anteriores.
2. **Concentración de Ingresos (Segmento Gold):** El análisis de segmentación dinámica reveló que un grupo muy reducido de usuarios (como Lucía Méndez) supera la barrera de los $5000 en gasto acumulado, sosteniendo gran parte de la facturación mediante compras recurrentes.
3. **Fugas en el embudo (Churn):** A través del cruce de tablas (`LEFT JOIN`), se identificaron clientes registrados históricamente (ej. Jorge Pérez y Martín Silva) que ingresaron a la plataforma pero jamás concretaron una transacción, representando oportunidades perdidas de conversión.

## Conclusiones para el análisis
* **Implementación de Triggers o Restricciones:** A nivel arquitectura, se recomienda modificar la base de datos para que la columna `descuento_aplicado` tenga un valor por defecto de `0.00` (`DEFAULT 0.00`), eliminando la necesidad de depender constantemente de `COALESCE` en la capa de análisis.
* **Campaña de Reactivación:** Se debe exportar la lista de correos obtenida en el "Análisis de Churn" para que el equipo de marketing envíe una campaña de email con un descuento agresivo en la primera compra, buscando reactivar a esos usuarios "dormidos".
* **Programa de Fidelidad VIP:** Los clientes etiquetados como "Gold" en nuestra categorización dinámica deben ser ingresados inmediatamente a un programa de fidelización exclusivo para asegurar su retención a largo plazo.

