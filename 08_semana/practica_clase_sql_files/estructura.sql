-- 1. Creación de Tablas
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_registro DATE NOT NULL,
    ultima_conexion DATE
);

CREATE TABLE ordenes (
    orden_id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(cliente_id),
    fecha_compra DATE NOT NULL,
    monto_bruto NUMERIC(10, 2) NOT NULL,
    descuento_aplicado NUMERIC(10, 2) -- Puede ser NULL, ideal para practicar COALESCE
);

-- 2. Inserción de Datos de Prueba
INSERT INTO clientes (nombre, email, fecha_registro, ultima_conexion) VALUES
('Carlos Santanna', 'carlos@email.com', '2023-01-10', '2024-03-01'),
('Lucía Méndez', 'lucia@email.com', '2023-02-15', '2024-03-05'),
('Jorge Pérez', 'jorge@email.com', '2022-11-20', '2023-05-10'), -- Cliente inactivo (Churn)
('Ana Gómez', 'ana@email.com', '2023-06-01', '2024-03-10'),
('Martín Silva', 'martin@email.com', '2023-08-14', '2023-09-01'), -- Cliente inactivo (Churn)
('Sofía Reyes', 'sofia@email.com', '2023-12-05', '2024-02-28');

-- Inserción de órdenes (Algunas sin descuento para generar NULLs)
INSERT INTO ordenes (cliente_id, fecha_compra, monto_bruto, descuento_aplicado) VALUES
(1, '2023-02-01', 1500.00, 100.00),
(1, '2023-05-15', 2000.00, NULL),
(2, '2023-03-10', 5000.00, 500.00),
(2, '2023-08-20', 4500.00, NULL),
(2, '2024-01-15', 3000.00, 300.00),
(4, '2023-07-01', 800.00, NULL),
(4, '2023-11-11', 1200.00, 150.00),
(6, '2024-01-05', 6000.00, 600.00);
-- Jorge y Martín no tienen órdenes recientes, o no tienen órdenes en absoluto.

