-- 1. Top 5 clientes por gasto total
-- Objetivo de negocio: Identificar a nuestros clientes "ballena" para futuras campañas de fidelización VIP.
-- Nota técnica: Usamos COALESCE para asegurar que los pedidos sin descuento no rompan la operación matemática retornando NULL.
SELECT 
    c.nombre,
    SUM((p.precio * ped.cantidad) - COALESCE(ped.descuento_aplicado, 0)) AS gasto_total
FROM 
    clientes c
JOIN 
    pedidos ped ON c.cliente_id = ped.cliente_id
JOIN 
    productos p ON ped.producto_id = p.producto_id
GROUP BY 
    c.nombre
ORDER BY 
    gasto_total DESC
LIMIT 5;

-- 2. Ventas totales por mes
-- Objetivo de negocio: Entender la estacionalidad del negocio y preparar el stock/marketing para los meses de mayor demanda.
SELECT 
    TO_CHAR(ped.fecha_pedido, 'YYYY-MM') AS mes,
    SUM((p.precio * ped.cantidad) - COALESCE(ped.descuento_aplicado, 0)) AS ingresos_totales,
    COUNT(ped.pedido_id) AS volumen_transacciones
FROM 
    pedidos ped
JOIN 
    productos p ON ped.producto_id = p.producto_id
GROUP BY 
    TO_CHAR(ped.fecha_pedido, 'YYYY-MM')
ORDER BY 
    mes ASC;

-- 3. 3 productos menos vendidos
-- Objetivo de negocio: Detectar productos con baja rotación para liquidar inventario o replantear la estrategia de precios.
SELECT 
    p.nombre,
    p.categoria,
    SUM(ped.cantidad) AS unidades_vendidas
FROM 
    productos p
LEFT JOIN 
    pedidos ped ON p.producto_id = ped.producto_id
GROUP BY 
    p.nombre, p.categoria
ORDER BY 
    unidades_vendidas ASC
LIMIT 3;

-- 4. Ranking de pedidos por categoría con RANK()
-- Objetivo de negocio: Identificar cuáles son los productos estrella dentro de cada categoría para optimizar la ubicación en la tienda online.
WITH VentasPorProducto AS (
    SELECT 
        p.categoria,
        p.nombre,
        SUM((p.precio * ped.cantidad) - COALESCE(ped.descuento_aplicado, 0)) AS ingresos_generados
    FROM 
        productos p
    JOIN 
        pedidos ped ON p.producto_id = ped.producto_id
    GROUP BY 
        p.categoria, p.nombre
)
SELECT 
    categoria,
    nombre,
    ingresos_generados,
    RANK() OVER(PARTITION BY categoria ORDER BY ingresos_generados DESC) as ranking_categoria
FROM 
    VentasPorProducto;

