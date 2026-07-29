-- Crear 2 tablas relacionadas sobre usuarios * - 1 < prestamo(transacciones) > 1 - *  libro
DROP TABLE IF EXISTS prestamos;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS libros;



CREATE TABLE  usuarios(
	id_usuario SERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL, 
	email VARCHAR(150) UNIQUE NOT NULL,
	fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

CREATE TABLE libros(
	id_libro SERIAL PRIMARY KEY,
	titulo VARCHAR(250),
	autor VARCHAR(150) NOT NULL,
	isbn VARCHAR(20) NOT NULL,
	stock INT DEFAULT 1 CHECK (stock > 0)
);

CREATE TABLE prestamos(
	id_prestamo SERIAL PRIMARY KEY,
	id_usuario INT NOT NULL,
	id_libro INT NOT NULL,
	fecha_prestamo DATE DEFAULT CURRENT_DATE,
	fecha_devolucion DATE ,
	estado BOOL DEFAULT TRUE,
	
	CONSTRAINT fk_usuario -- nombre que le das al constraints
		FOREIGN KEY (id_usuario) -- definido en esta tabla
		REFERENCES usuarios (id_usuario), -- la tabla a donde le hago referencia
		
	CONSTRAINT fk_libro -- nombre que le das al constraints
		FOREIGN KEY (id_libro) -- definido en esta tabla
		REFERENCES libros (id_libro) -- la tabla a donde le hago referencia
			
);

-- alter table



SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE table_name = 'prestamos';

-- inicio de transaccion
BEGIN;

INSERT INTO usuarios (nombre,email)
VALUES
('pirulo', 'pirulo_boca_boca_boca@mail.com');

SELECT * FROM usuarios;


ROLLBACK;
COMMIT;

END;




