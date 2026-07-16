# Normalización de una Base de Datos de Fútbol (PostgreSQL)

Material para introducir 1FN, 2FN y 3FN partiendo de una tabla única, desnormalizada y con datos "sucios", hasta llegar a un modelo relacional simple con `Equipo`, `Jugador` y `Partido`.

---

## 1. Punto de partida: la tabla "sucia"

Así llegan los datos crudos (por ejemplo, exportados de una planilla de Excel):

```sql
CREATE TABLE partidos_sucios (
    partido_id      INT,
    fecha           DATE,
    estadio         TEXT,
    ciudad_estadio  TEXT,
    equipo_local    TEXT,
    equipo_visitante TEXT,
    goles_local     INT,
    goles_visitante INT,
    jugador         TEXT,
    dorsal          INT,
    equipo_jugador  TEXT,
    gol_marcado     INT   -- cantidad de goles que hizo ESE jugador en ESE partido
);
```

Datos de ejemplo (dos partidos, tres jugadores anotadores cada uno):

```sql
INSERT INTO partidos_sucios VALUES
(1, '2026-05-01', 'La Bombonera', 'Buenos Aires', 'Boca',  'River', 2, 1, 'Juan Perez',    10, 'Boca',  1),
(1, '2026-05-01', 'La Bombonera', 'Buenos Aires', 'Boca',  'River', 2, 1, 'Carlos Diaz',    9, 'Boca',  1),
(1, '2026-05-01', 'La Bombonera', 'Buenos Aires', 'Boca',  'River', 2, 1, 'Marcos Rojas',   7, 'River', 1),
(2, '2026-05-08', 'El Monumental','Buenos Aires', 'River', 'Boca',  3, 3, 'Marcos Rojas',   7, 'River', 2),
(2, '2026-05-08', 'El Monumental','Buenos Aires', 'River', 'Boca',  3, 3, 'Juan Perez',    10, 'Boca',  2),
(2, '2026-05-08', 'El Monumental','Buenos Aires', 'River', 'Boca',  3, 3, 'Carlos Diaz',    9, 'Boca',  1);
```

### ¿Por qué está "sucia"?

Preguntá a los alumnos qué pasa si:

- **Boca cambia de nombre de estadio** → hay que actualizar todas las filas donde aparece "La Bombonera" (anomalía de actualización).
- **Se quiere cargar un jugador nuevo que todavía no jugó ningún partido** → no se puede, porque `jugador` solo existe dentro de una fila de `partido` (anomalía de inserción).
- **Se borra el único partido cargado de un equipo** → se pierde también el dato de qué jugadores tiene ese equipo y su dorsal (anomalía de borrado).
- El nombre y la ciudad de cada equipo, el dorsal de cada jugador, etc. **se repiten** una y otra vez → redundancia y riesgo de inconsistencia (¿y si en una fila "River" está escrito "Riber"?).

Esto pasa porque estamos mezclando en una sola tabla tres conceptos distintos: **equipo**, **jugador** y **partido** (y la relación "quién metió un gol en qué partido").

---

## 2. Primera Forma Normal (1FN)

**Regla:** cada columna debe tener un único valor atómico, sin listas ni repeticiones dentro de una celda, y no debe haber grupos de columnas repetidas.

En nuestra tabla los valores ya son atómicos (no hay "Juan Perez, Carlos Diaz" en una sola celda), así que técnicamente ya cumple 1FN a nivel de celda. El problema real que tiene es que **una misma fila mezcla datos de tres entidades distintas** (equipo, jugador, partido), lo cual se resuelve en los pasos siguientes.

---

## 3. Segunda Forma Normal (2FN)

**Regla:** ya cumple 1FN, y además ningún atributo no clave depende solo de una *parte* de una clave compuesta.

Si pensamos la clave de `partidos_sucios` como `(partido_id, jugador)`, notamos que:

- `fecha`, `estadio`, `ciudad_estadio`, `equipo_local`, `equipo_visitante`, `goles_local`, `goles_visitante` dependen **solo de `partido_id`** (no del jugador).
- `dorsal`, `equipo_jugador` dependen **solo de `jugador`** (no del partido).
- Solo `gol_marcado` depende de **ambos** (`partido_id` + `jugador`) a la vez.

Esto es justamente una dependencia parcial: separamos en tres tablas.

```sql
-- Equipo
CREATE TABLE equipo (
    equipo_id   SERIAL PRIMARY KEY,
    nombre      TEXT NOT NULL UNIQUE
);

-- Partido (sin repetir datos de equipo)
CREATE TABLE partido (
    partido_id       SERIAL PRIMARY KEY,
    fecha            DATE NOT NULL,
    estadio          TEXT,
    equipo_local_id      INT NOT NULL REFERENCES equipo(equipo_id),
    equipo_visitante_id  INT NOT NULL REFERENCES equipo(equipo_id),
    goles_local      INT NOT NULL,
    goles_visitante  INT NOT NULL
);

-- Jugador (sin repetir nombre de equipo como texto)
CREATE TABLE jugador (
    jugador_id  SERIAL PRIMARY KEY,
    nombre      TEXT NOT NULL,
    dorsal      INT,
    equipo_id   INT NOT NULL REFERENCES equipo(equipo_id)
);
```

---

## 4. Tercera Forma Normal (3FN)

**Regla:** ya cumple 2FN, y además ningún atributo no clave depende de otro atributo no clave (dependencia transitiva).

En la tabla original, `ciudad_estadio` dependía de `estadio`, no directamente de `partido_id` (dependencia transitiva: `partido_id → estadio → ciudad_estadio`). Para mantenerlo simple con alumnos que recién arrancan, alcanza con dejar `estadio` como un texto libre dentro de `partido` y **no** crear todavía una tabla `estadio` aparte (se los puede proponer como ejercicio extra).

Lo que sí queda pendiente es la relación **jugador–partido**, porque un jugador puede convertir goles en muchos partidos, y un partido puede tener goles de muchos jugadores: es una relación **muchos a muchos**, que necesita su propia tabla intermedia.

```sql
-- Tabla intermedia: goles convertidos por un jugador en un partido
CREATE TABLE gol (
    gol_id      SERIAL PRIMARY KEY,
    partido_id  INT NOT NULL REFERENCES partido(partido_id),
    jugador_id  INT NOT NULL REFERENCES jugador(jugador_id),
    cantidad    INT NOT NULL DEFAULT 1,
    UNIQUE (partido_id, jugador_id)
);
```

---

## 5. Modelo final y cardinalidades

| Relación | Cardinalidad | Lectura |
|---|---|---|
| `equipo` → `jugador` | 1 : N | Un equipo tiene muchos jugadores; un jugador pertenece a un solo equipo |
| `equipo` → `partido` (local) | 1 : N | Un equipo juega de local en muchos partidos; cada partido tiene un solo equipo local |
| `equipo` → `partido` (visitante) | 1 : N | Un equipo juega de visitante en muchos partidos; cada partido tiene un solo equipo visitante |
| `jugador` ↔ `partido` (vía `gol`) | N : M | Un jugador puede marcar goles en muchos partidos; un partido puede tener goles de muchos jugadores distintos |

Diagrama simplificado (texto):

```
equipo (1) ───< (N) jugador
equipo (1) ───< (N) partido.equipo_local_id
equipo (1) ───< (N) partido.equipo_visitante_id

jugador (1) ───< (N) gol >─── (1) partido
       (jugador y partido quedan relacionados N:M a través de gol)
```

---

## 6. Script completo (para copiar y pegar)

```sql
DROP TABLE IF EXISTS gol, jugador, partido, equipo, partidos_sucios CASCADE;

CREATE TABLE equipo (
    equipo_id   SERIAL PRIMARY KEY,
    nombre      TEXT NOT NULL UNIQUE
);

CREATE TABLE partido (
    partido_id           SERIAL PRIMARY KEY,
    fecha                DATE NOT NULL,
    estadio              TEXT,
    equipo_local_id      INT NOT NULL REFERENCES equipo(equipo_id),
    equipo_visitante_id  INT NOT NULL REFERENCES equipo(equipo_id),
    goles_local          INT NOT NULL,
    goles_visitante      INT NOT NULL,
    CHECK (equipo_local_id <> equipo_visitante_id)
);

CREATE TABLE jugador (
    jugador_id  SERIAL PRIMARY KEY,
    nombre      TEXT NOT NULL,
    dorsal      INT,
    equipo_id   INT NOT NULL REFERENCES equipo(equipo_id)
);

CREATE TABLE gol (
    gol_id      SERIAL PRIMARY KEY,
    partido_id  INT NOT NULL REFERENCES partido(partido_id),
    jugador_id  INT NOT NULL REFERENCES jugador(jugador_id),
    cantidad    INT NOT NULL DEFAULT 1,
    UNIQUE (partido_id, jugador_id)
);

-- Datos de ejemplo
INSERT INTO equipo (nombre) VALUES ('Boca'), ('River');

INSERT INTO jugador (nombre, dorsal, equipo_id) VALUES
('Juan Perez',  10, 1),
('Carlos Diaz',  9, 1),
('Marcos Rojas',  7, 2);

INSERT INTO partido (fecha, estadio, equipo_local_id, equipo_visitante_id, goles_local, goles_visitante) VALUES
('2026-05-01', 'La Bombonera',  1, 2, 2, 1),
('2026-05-08', 'El Monumental', 2, 1, 3, 3);

INSERT INTO gol (partido_id, jugador_id, cantidad) VALUES
(1, 1, 1),  -- Juan Perez, partido 1
(1, 2, 1),  -- Carlos Diaz, partido 1
(1, 3, 1),  -- Marcos Rojas, partido 1
(2, 3, 2),  -- Marcos Rojas, partido 2
(2, 1, 2),  -- Juan Perez, partido 2
(2, 2, 1);  -- Carlos Diaz, partido 2
```

### Consulta de verificación

```sql
SELECT p.fecha, el.nombre AS local, ev.nombre AS visitante,
       j.nombre AS jugador, g.cantidad AS goles
FROM gol g
JOIN partido p ON p.partido_id = g.partido_id
JOIN equipo el ON el.equipo_id = p.equipo_local_id
JOIN equipo ev ON ev.equipo_id = p.equipo_visitante_id
JOIN jugador j ON j.jugador_id = g.jugador_id
ORDER BY p.fecha, g.cantidad DESC;
```

---

## Ejercicios que recomiendo

1. Agregar la tabla `estadio` (con `nombre` y `ciudad`) y referenciarla desde `partido`, para practicar 3FN de nuevo.
2. Escribir la consulta que devuelva el goleador de todo el campeonato.
3. ¿Qué pasaría si un jugador cambia de equipo a mitad de temporada? Discutir si `jugador.equipo_id` alcanza o hace falta una tabla `pase` con fecha.