-- 1. Construcción del Dashboard Analítico: Top 5 mejores clientes y promedio de compra
-- Se utiliza COALESCE para evitar que los descuentos NULL arruinen el cálculo matemático.
SELECT 
    c.nombre,
    COUNT(o.orden_id) AS total_compras,
    SUM(o.monto_bruto - COALESCE(o.descuento_aplicado, 0)) AS valor_total_generado,
    ROUND(AVG(o.monto_bruto - COALESCE(o.descuento_aplicado, 0)), 2) AS ticket_promedio
FROM 
    clientes c
JOIN 
    ordenes o ON c.cliente_id = o.cliente_id
GROUP BY 
    c.cliente_id, c.nombre
ORDER BY 
    valor_total_generado DESC
LIMIT 5;

-- 2. Análisis de Churn (Bajas): Clientes sin compras registradas
-- Se utiliza LEFT JOIN y se filtra donde el ID de la orden es NULL para encontrar inactivos.
SELECT 
    c.nombre,
    c.email,
    c.fecha_registro,
    c.ultima_conexion
FROM 
    clientes c
LEFT JOIN 
    ordenes o ON c.cliente_id = o.cliente_id
WHERE 
    o.orden_id IS NULL;

-- 3. Categorización Dinámica: Segmentación Gold, Silver, Bronze
-- Se utiliza CASE WHEN para clasificar según el volumen de gasto histórico.
WITH GastoClientes AS (
    SELECT 
        c.cliente_id,
        c.nombre,
        SUM(o.monto_bruto - COALESCE(o.descuento_aplicado, 0)) AS gasto_total
    FROM 
        clientes c
    JOIN 
        ordenes o ON c.cliente_id = o.cliente_id
    GROUP BY 
        c.cliente_id, c.nombre
)
SELECT 
    nombre,
    gasto_total,
    CASE 
        WHEN gasto_total >= 5000 THEN 'Gold'
        WHEN gasto_total >= 2000 THEN 'Silver'
        ELSE 'Bronze'
    END AS segmento_cliente
FROM 
    GastoClientes
ORDER BY 
    gasto_total DESC;
