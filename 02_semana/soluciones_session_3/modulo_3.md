#### Preparación del Entorno (Setup)

Antes de iniciar el simulacro, los alumnos deben preparar la tabla `usuarios` ejecutando este bloque. Se incluye una restricción `CHECK` fundamental: el saldo nunca puede ser menor a cero.

```sql
-- Agregar columna de saldo a la tabla usuarios
ALTER TABLE usuarios 
ADD COLUMN saldo NUMERIC(10, 2) DEFAULT 0.00;

-- Asegurar que nadie tenga saldo negativo
ALTER TABLE usuarios 
ADD CONSTRAINT check_saldo_positivo CHECK (saldo >= 0);

-- Fondeo inicial de cuentas para el ejercicio
UPDATE usuarios SET saldo = 1000.00 WHERE id_usuario = 1;
UPDATE usuarios SET saldo = 500.00 WHERE id_usuario = 2;

```

#### 1 y 2. Análisis de la Demo e Implementación de Control (`BEGIN`, `COMMIT`, `ROLLBACK`)

Para demostrar qué sucede cuando no hay transacciones y cómo proteger los datos, se propone la siguiente secuencia de comandos para que los alumnos ejecuten línea por línea.

**Demostración de Transacción Exitosa:**

```sql
-- Iniciar el bloque transaccional
BEGIN;

-- Ejecutar una modificación
UPDATE usuarios 
SET saldo = saldo - 100 
WHERE id_usuario = 1;

-- En este punto, si abren OTRA conexión a la base de datos, verán que el usuario 1 
-- todavía tiene 1000.00. El cambio solo vive en la sesión actual.

-- Confirmar los cambios definitivamente
COMMIT;

```

**Demostración de Aborto Manual:**

```sql
BEGIN;

-- Actualización masiva por error (sin WHERE)
UPDATE usuarios SET saldo = 0;

-- Al detectar el error, revertimos todo el bloque
ROLLBACK;
-- Todos los saldos vuelven a su estado original antes del BEGIN.

```

#### 3. El Desafío de la Transferencia (Simulacro de Falla)

El objetivo de este script es demostrar el principio de "Atomicidad" de las bases de datos (propiedades ACID). La operación es un "todo o nada". Vamos a simular que el Usuario 1 le transfiere 300 al Usuario 2, pero provocaremos un error sintáctico intencional en el segundo paso.

```sql
-- Verificar estado inicial
-- Usuario 1 debería tener 900.00 y Usuario 2 tener 500.00

BEGIN;

-- Paso 1: Descuento al Usuario A (id = 1) -> ESTO SE EJECUTA CON ÉXITO
UPDATE usuarios 
SET saldo = saldo - 300 
WHERE id_usuario = 1;

-- Paso 2: Ingreso al Usuario B (id = 2) -> ERROR INTENCIONAL
-- Intentamos sumar un tipo de dato incompatible (texto en lugar de número)
UPDATE usuarios 
SET saldo = saldo + 'trescientos' 
WHERE id_usuario = 2;

-- El motor de base de datos arroja un error: 
-- "invalid input syntax for type numeric"

-- Paso 3: Intento de Commit
COMMIT;
-- El motor rechazará el COMMIT informando: 
-- "current transaction is aborted, commands ignored until end of transaction block"

-- Paso 4: Reversión obligatoria
ROLLBACK;

-- Verificar estado final
SELECT id_usuario, nombre_usuario, saldo FROM usuarios;
-- El Usuario 1 recuperó automáticamente sus 300, garantizando que el dinero no se "esfumó" del sistema por el fallo en el Paso 2.

```
