# Material de Práctica: Dominando el Diseño y la Manipulación de Datos

## Laboratorio Práctico: Completando la Biblioteca Digital

Aquí tienes las soluciones exactas que los estudiantes deben alcanzar en la Actividad 1. Al usar PostgreSQL, aprovecharemos el tipo `SERIAL` y las restricciones de fecha.

```sql
-- 1. Tabla Usuarios
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20)
);

-- 2. Tabla Préstamos (La tabla "puente" que une todo)
CREATE TABLE prestamos (
    id_prestamo SERIAL PRIMARY KEY,
    id_libro INT NOT NULL REFERENCES libros(id_libro),
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario),
    fecha_prestamo DATE DEFAULT CURRENT_DATE, 
    fecha_devolucion DATE,
    -- Restricción de negocio: la devolución no puede ser antes del préstamo
    CONSTRAINT chk_fechas CHECK (fecha_devolucion >= fecha_prestamo) 
);

```

> **Tip para el instructor:** Muestra a los estudiantes cómo usar `DEFAULT CURRENT_DATE` en PostgreSQL. Es un excelente momento para explicar que la base de datos puede automatizar el registro de la fecha actual sin que ellos tengan que insertarla manualmente.

---

## Ejercicio de Transacciones: Transferencia Bancaria

Para la Actividad 3, se pidió a los estudiantes simular una transferencia. Aquí tienes el paso a paso exacto de cómo debería verse una transferencia segura en PostgreSQL.

### Paso 1: Preparar el entorno (Setup)

*Ejecutar antes de iniciar el ejercicio para tener datos de prueba.*

```sql
CREATE TABLE cuentas (
    id_cuenta SERIAL PRIMARY KEY,
    titular VARCHAR(50) NOT NULL,
    saldo DECIMAL(10,2) CHECK (saldo >= 0) -- Evita saldos negativos
);

INSERT INTO cuentas (titular, saldo) VALUES 
    ('Ana', 1000.00),
    ('Juan', 500.00);

```

### Paso 2: Iniciar la transacción segura

```sql
BEGIN;

```

### Paso 3: Ejecutar los movimientos

```sql
-- 1. Descontar 200 de Ana
UPDATE cuentas SET saldo = saldo - 200 WHERE id_cuenta = 1;

-- 2. Sumar 200 a Juan
UPDATE cuentas SET saldo = saldo + 200 WHERE id_cuenta = 2;

```

### Paso 4: Verificar antes de confirmar

*En este punto, solo la sesión actual ve los cambios. El resto de la base de datos no.*

```sql
SELECT * FROM cuentas;

```

### Paso 5: Confirmar (o deshacer) los cambios

```sql
-- Si todo está correcto y los saldos cuadran:
COMMIT;

-- Si hubo una equivocación de cuenta o monto:
-- ROLLBACK;

```

---

## Trucos de PostgreSQL para el cierre de clase

Al final de la sesión, puedes compartir estos comandos específicos de PostgreSQL para optimizar el trabajo (ideal si utilizan PgAdmin o la consola `psql`):

* **La cláusula RETURNING:** En PostgreSQL, puedes ver el registro que acabas de insertar (incluyendo el ID autogenerado) sin necesidad de hacer un `SELECT` extra.
```sql
INSERT INTO usuarios (nombre, email) 
VALUES ('Carlos', 'carlos@email.com') 
RETURNING id_usuario, nombre;

```


* **Inspeccionar tablas (en psql):** Si usan la terminal, el comando `\d nombre_tabla` es invaluable. Les mostrará toda la estructura, los tipos de datos, las claves primarias y las claves foráneas de un solo vistazo.

```sql
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_name = $nombre_tabla;
```