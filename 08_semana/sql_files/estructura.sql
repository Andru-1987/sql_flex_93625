
-- ==========================================
-- Archivo: estructura.sql
-- ==========================================

-- Creación de la base de datos (Ejecutar por separado si es necesario)
-- CREATE DATABASE capstone_project;

-- 1. Creación de Tablas
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    fecha_registro DATE NOT NULL
);

CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    precio NUMERIC(10, 2) NOT NULL
);

CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(cliente_id),
    producto_id INT REFERENCES productos(producto_id),
    fecha_pedido DATE NOT NULL,
    cantidad INT NOT NULL,
    descuento_aplicado NUMERIC(10, 2) -- Columna con posibles nulos para usar COALESCE
);

-- 2. Inserción de Datos (Mock Data)
INSERT INTO clientes (nombre, email, fecha_registro) VALUES
('Ana García', 'ana@email.com', '2023-01-15'),
('Carlos López', 'carlos@email.com', '2023-02-20'),
('María Rodríguez', 'maria@email.com', '2023-03-10'),
('Juan Pérez', 'juan@email.com', '2023-04-05'),
('Lucía Fernández', 'lucia@email.com', '2023-05-12'),
('Marcos Díaz', 'marcos@email.com', '2023-06-01');

INSERT INTO productos (nombre, categoria, precio) VALUES
('Laptop Pro', 'Electrónica', 1200.00),
('Monitor 27"', 'Electrónica', 300.00),
('Silla Ergonómica', 'Mobiliario', 250.00),
('Teclado Mecánico', 'Electrónica', 100.00),
('Escritorio Standing', 'Mobiliario', 450.00),
('Mouse Inalámbrico', 'Electrónica', 50.00);

-- Insertamos pedidos, dejando algunos descuentos en NULL para simular datos sucios
INSERT INTO pedidos (cliente_id, producto_id, fecha_pedido, cantidad, descuento_aplicado) VALUES
(1, 1, '2023-07-01', 1, 100.00),
(1, 2, '2023-07-05', 2, NULL),
(2, 3, '2023-07-10', 4, 50.00),
(3, 4, '2023-08-01', 1, NULL),
(4, 5, '2023-08-15', 1, 20.00),
(5, 1, '2023-09-01', 2, 200.00),
(5, 6, '2023-09-02', 5, NULL),
(1, 3, '2023-09-15', 1, 15.00),
(2, 6, '2023-10-01', 1, NULL),
(3, 1, '2023-10-10', 1, 50.00);

