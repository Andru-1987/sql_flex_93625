## Diseño y Manipulación de Datos (DDL y DML)

Este módulo aborda la construcción de contenedores de datos robustos mediante el Lenguaje de Definición de Datos (DDL), así como la gestión de su contenido mediante el Lenguaje de Manipulación de Datos (DML) y el uso de transacciones.

## 1. Diseño de Estructuras de Datos (DDL)

El DDL agrupa los comandos necesarios para definir, modificar o eliminar la estructura de los objetos de la base de datos, como tablas, esquemas o índices. Su enfoque principal es la arquitectura del contenedor y no los datos en sí.

* **CREATE TABLE:** Comando inicial para la creación de una tabla. Define su nombre (preferentemente en minúsculas y plural en PostgreSQL) y las columnas con sus respectivos tipos de datos.
* **Tipo SERIAL:** Tipo de dato específico de PostgreSQL que genera números enteros autoincrementales de forma automática. Es el estándar para identificadores únicos (IDs).
* **ALTER TABLE:** Permite modificar la estructura de una tabla existente ante cambios en los requerimientos. Operaciones comunes incluyen `ADD COLUMN` (añadir), `DROP COLUMN` (eliminar) y `ALTER COLUMN ... TYPE` (modificar tipo de dato).
* **DROP TABLE:** Elimina la tabla y todos sus datos de forma permanente. Dado que SQL no posee un mecanismo de recuperación, es una instrucción crítica. Se recomienda el uso de la cláusula `IF EXISTS` para evitar errores de ejecución si el objeto no se encuentra en la base de datos.

### Diferencia entre DROP y TRUNCATE

* **DROP TABLE:** Elimina la estructura de la tabla y la totalidad de sus registros del sistema.
* **TRUNCATE TABLE:** Elimina todos los registros de la tabla, pero conserva la estructura intacta para futuras inserciones.

---

## 2. Restricciones de Integridad (Constraints)

Las restricciones son reglas aplicadas a las columnas para delimitar los datos admisibles. Su propósito es prevenir el ingreso de información inconsistente y asegurar la calidad de la base de datos.

* **PRIMARY KEY (PK):** Identifica de forma unívoca cada fila de una tabla. No admite valores duplicados ni nulos (`NOT NULL`). Su definición genera automáticamente un índice B-Tree para optimizar las consultas.
* **FOREIGN KEY (FK):** Columna que enlaza con la clave primaria de otra tabla para garantizar la integridad referencial. Su función es prevenir la existencia de registros dependientes sin un registro padre asociado.
* **RESTRICT:** Comportamiento de borrado por defecto de una FK. Impide eliminar un registro padre si este posee registros dependientes.
* **CASCADE:** Comportamiento de borrado alternativo de una FK. Al eliminar un registro en la tabla padre, el sistema elimina automáticamente sus registros dependientes.
* **CHECK:** Define condiciones lógicas obligatorias para la inserción de datos. Ejemplos comunes incluyen validaciones matemáticas (`precio > 0`), validación de listas (`estado IN ('Pendiente', 'Entregado')`) o secuencias temporales (`fecha_entrega >= fecha_pedido`).
* **NOT NULL:** Exige que la columna contenga un valor obligatoriamente.
* **UNIQUE:** Impide la existencia de valores duplicados dentro de una misma columna.

> **Principio de diseño DDL:** El orden de creación es estricto. Primero se deben estructurar las tablas independientes (padres) y posteriormente las tablas dependientes (hijas) que albergarán las claves foráneas.

---

## 3. Inserción de Datos

Para poblar las tablas, PostgreSQL provee mecanismos adaptados según el volumen de la información:

* **INSERT:** Comando utilizado para agregar registros de forma controlada o manual. Es óptimo para volúmenes reducidos y permite tanto inserciones individuales como múltiples mediante una lista separada por comas.
* **COPY:** Herramienta nativa de alto rendimiento diseñada para la importación masiva de datos desde archivos externos (CSV o TXT). Requiere la ruta absoluta del archivo en el sistema y admite parámetros de configuración como `FORMAT csv`, `HEADER true` (omite la primera fila), `DELIMITER` (define el separador) y `ENCODING 'UTF8'`.
* **ON CONFLICT:** Cláusula que previene la interrupción de una carga masiva ante un error de clave duplicada. Permite establecer un comportamiento de resolución, como la actualización del registro existente (`ON CONFLICT (id) DO UPDATE SET ...`).

---

## 4. Manipulación Segura: UPDATE, DELETE y Transacciones

* **UPDATE:** Modifica los valores de los registros existentes. Permite redefinir datos fijos o ejecutar cálculos matemáticos iterativos. Su uso requiere obligatoriamente la cláusula `WHERE`; su omisión resultará en la modificación indiscriminada de toda la tabla.
* **DELETE:** Elimina registros específicos manteniendo la estructura del contenedor. Al igual que el comando anterior, la ausencia de la cláusula `WHERE` provocará el vaciado completo de la tabla.

### Control de Transacciones

Las transacciones aseguran que las operaciones críticas cumplan con los principios ACID (Atomicidad, Consistencia, Aislamiento y Durabilidad).

* **BEGIN:** Inicializa la transacción. Las modificaciones posteriores operan en una memoria temporal, permaneciendo invisibles para el resto de los usuarios de la base de datos.
* **COMMIT:** Confirma de forma definitiva los cambios temporales, escribiéndolos en el disco.
* **ROLLBACK:** Revierte la totalidad de las operaciones ejecutadas desde la instrucción `BEGIN`, restaurando el estado previo de los datos.

> **Procedimiento de seguridad:** Previo a la ejecución de sentencias `UPDATE` o `DELETE` complejas, se recomienda ejecutar una consulta `SELECT` utilizando la misma cláusula `WHERE`. Esto permite verificar los resultados y asegurar que la afectación de registros sea precisa.