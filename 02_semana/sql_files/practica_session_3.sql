-- creando base de datos
CREATE DATABASE spotty_coder;

-- creando un schema core_negocio
CREATE SCHEMA IF NOT EXISTS core_negocio;


-- Creación de tabla Usuarios
CREATE TABLE core_negocio.usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    fecha_registro DATE DEFAULT CURRENT_DATE
);

-- Creación de tabla Canciones
CREATE TABLE core_negocio.canciones (
    id_cancion SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    artista VARCHAR(100) NOT NULL,
    duracion_segundos INT CHECK (duracion_segundos > 0), -- condiciona a mi informacion para otorgarle la posibilidad de no ingresar informacion que no cumpla esta conicion
    genero VARCHAR(50)
);

-- Creación de tabla Playlists
CREATE TABLE core_negocio.playlists (
    id_playlist SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    fecha_creacion DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (id_usuario) REFERENCES core_negocio.usuarios(id_usuario) ON DELETE CASCADE
);

-- Creación de tabla intermedia para la relación Muchos a Muchos
CREATE TABLE core_negocio.playlist_canciones (
    id_playlist INT NOT NULL,
    id_cancion INT NOT NULL,
    fecha_agregada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_playlist, id_cancion), -- concatenada 
    FOREIGN KEY (id_playlist) REFERENCES core_negocio.playlists(id_playlist) ON DELETE CASCADE,
    FOREIGN KEY (id_cancion) REFERENCES core_negocio.canciones(id_cancion) ON DELETE CASCADE
);




-- INSERT INTO  DATA


-- Inserción de Usuarios
INSERT INTO core_negocio.usuarios (nombre_usuario, email) VALUES
('usuario_rockero', 'rock@ejemplo.com'),
('lofi_student', 'lofi@ejemplo.com'),
('dj_admin', 'dj@ejemplo.com');

-- Inserción de Canciones
INSERT INTO core_negocio.canciones (titulo, artista, duracion_segundos, genero) VALUES
('Bohemian Rhapsody', 'Queen', 354, 'Rock'),
('Stairway to Heaven', 'Led Zeppelin', 482, 'Rock'),
('Midnight City', 'M83', 243, 'Indie Pop'),
('Weightless', 'Marconi Union', 491, 'Ambient'),
('Around the World', 'Daft Punk', 429, 'Electronic');

-- Inserción de Playlists
INSERT INTO core_negocio.playlists (id_usuario, nombre) VALUES
(1, 'Clasicos del Rock'),
(2, 'Estudio y Concentracion'),
(3, 'Fiesta Electronica');

-- Asociación de Canciones a Playlists
INSERT INTO core_negocio.playlist_canciones (id_playlist, id_cancion) VALUES
(1, 1), -- Bohemian Rhapsody en Clasicos del Rock
(1, 2), -- Stairway to Heaven en Clasicos del Rock
(2, 4), -- Weightless en Estudio y Concentracion
(3, 3), -- Midnight City en Fiesta Electronica
(3, 1),
(3, 2),
(3, 5); -- Around the World en Fiesta Electronica


COPY core_negocio.canciones (titulo, artista, duracion_segundos, genero)
FROM '/data/canciones.csv'
DELIMITER ','
CSV HEADER;


 
-- Script de prueba: Cacería de Errores
-- Instrucción: Ejecute cada comando, lea el error del motor y corríjalo.

-- Error 1
INSERT INTO core_negocio.canciones (titulo, artista, duracion_segundos, genero) 
VALUES ('Silencio', 'John Cage', 0, 'Experimental');

-- Error 2
INSERT INTO core_negocio.usuarios (nombre_usuario) 
VALUES ('usuario_fantasma');

-- Error 3
INSERT INTO core_negocio.playlists (id_usuario, nombre) 
VALUES (9999, 'Tardes de Lluvia');

-- Error 4
UPDATE core_negocio.usuarios 
SET email = 'inactivo@ejemplo.com'
WHERE id_usuario = 2
;

-- Error 5
DROP TABLE core_negocio.usuarios CASCADE; -- JAMAS usar

-- Transacciones Peligrosas


-- tabla exixtente  sea modificada o manipulada
ALTER TABLE  core_negocio.usuarios 
	ADD COLUMN saldo NUMERIC(10,2) DEFAULT 0.00;


ALTER TABLE  core_negocio.usuarios
	ADD CONSTRAINT check_usuarios_saldo_positivo CHECK (saldo >=0);



UPDATE core_negocio.usuarios 
	SET saldo = 500.00 WHERE id_usuario = 2;


BEGIN ;
	UPDATE core_negocio.usuarios
		SET saldo = saldo - 1000.00
		WHERE  id_usuario = 1;

	SELECT * FROM core_negocio.usuarios;
	
	ROLLBACK;
END; --  es un commit





























