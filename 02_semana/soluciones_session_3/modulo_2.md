#### 1. El Script con Errores

```sql
-- Script de prueba: Cacería de Errores
-- Instrucción: Ejecute cada comando, lea el error del motor y corríjalo.

-- Error 1
INSERT INTO canciones (titulo, artista, duracion_segundos, genero) 
VALUES ('Silencio', 'John Cage', 0, 'Experimental');

-- Error 2
INSERT INTO usuarios (nombre_usuario) 
VALUES ('usuario_fantasma');

-- Error 3
INSERT INTO playlists (id_usuario, nombre) 
VALUES (9999, 'Tardes de Lluvia');

-- Error 4
UPDATE usuarios 
SET email = 'inactivo@ejemplo.com';

-- Error 5
DROP TABLE usuarios;

```

---

#### 2. Depuración y Documentación del Fallo (Resolución)

A continuación se detalla cómo deben corregir el código los estudiantes y la explicación técnica de por qué el motor de base de datos abortó cada transacción.

**Error 1: Violación de restricción CHECK**

* **Por qué fallaba:** La tabla `canciones` tiene una restricción `CHECK (duracion_segundos > 0)`. El script intentaba insertar un valor de `0`, lo cual evalúa como falso y bloquea la inserción.
* **Código corregido:**

```sql
INSERT INTO canciones (titulo, artista, duracion_segundos, genero) 
VALUES ('Silencio', 'John Cage', 1, 'Experimental');

```

**Error 2: Violación de restricción NOT NULL**

* **Por qué fallaba:** En el DDL, la columna `email` de la tabla `usuarios` fue definida como `NOT NULL`. Al omitir este campo en la sentencia `INSERT`, el motor rechaza el registro por falta de datos obligatorios.
* **Código corregido:**

```sql
INSERT INTO usuarios (nombre_usuario, email) 
VALUES ('usuario_fantasma', 'fantasma@ejemplo.com');

```

**Error 3: Violación de Clave Foránea (Integridad Referencial)**

* **Por qué fallaba:** Se intenta crear una playlist asignada al `id_usuario` 9999. Como ese ID no existe en la tabla `usuarios`, la restricción `FOREIGN KEY` impide la creación para evitar registros huérfanos.
* **Código corregido:** Asignar la playlist a un usuario existente (por ejemplo, ID 1).

```sql
INSERT INTO playlists (id_usuario, nombre) 
VALUES (1, 'Tardes de Lluvia');

```

**Error 4: UPDATE catastrófico y violación de UNIQUE**

* **Por qué fallaba:** Al omitir la cláusula `WHERE`, el comando intenta aplicar el mismo correo (`inactivo@ejemplo.com`) a todos los registros de la tabla. Al hacerlo en el segundo registro, choca con la restricción `UNIQUE` de la columna `email` y la operación se cancela por completo.
* **Código corregido:** Limitar el alcance de la actualización con un `WHERE`.

```sql
UPDATE usuarios 
SET email = 'inactivo@ejemplo.com'
WHERE id_usuario = 2;

```

**Error 5: DROP TABLE bloqueado por dependencias**

* **Por qué fallaba:** No se puede eliminar la tabla `usuarios` mediante un `DROP TABLE` simple porque la tabla `playlists` depende de ella a través de una Clave Foránea. El motor protege la integridad de los datos impidiendo que la tabla hija quede apuntando a una tabla inexistente.
* **Código corregido:** Existen dos formas de resolverlo. Eliminar primero las tablas dependientes, o forzar la eliminación en cascada de los objetos que dependen de esta tabla utilizando la cláusula `CASCADE`.

```sql
DROP TABLE usuarios CASCADE;

```
