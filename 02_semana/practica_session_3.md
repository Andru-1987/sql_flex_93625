# Dominando el Diseño y la Manipulación de Datos (DDL & DML)

### Objetivos de la session

En esta sesión, dejaremos de ver comandos aislados para entender el **ciclo de vida completo del dato**. Aprenderás a:

- **Diseñar con propósito:** Pasar de un requerimiento de negocio a una estructura DDL sólida.
- **Manipular con precisión:** Insertar, actualizar y eliminar datos (DML) de forma masiva y segura.
- **Resolver crisis:** Identificar y corregir errores comunes de integridad y sintaxis que detienen el desarrollo profesional.

### Temas clave

1. **Refuerzo DDL:** La importancia de las restricciones (PK, FK, CHECK) para evitar que la "basura" entre a nuestra base de datos.
2. **Operaciones DML de alto nivel:** Uso de transacciones para asegurar que nuestras operaciones sean "todo o nada".
3. **Integración Real:** Cómo DDL y DML trabajan juntos para mantener aplicaciones como Spotify o Airbnb.

---

### Módulo 1: Diseño y Poblamiento de Base de Datos

**Objetivo:** Modelar desde cero el esquema relacional para una aplicación de streaming musical estilo Spotify.

**Tareas a realizar:**

1. **Esquematizar:** Diseñar el modelo relacional identificando las entidades principales (**Usuarios**, **Canciones**, **Playlists**) y las relaciones entre ellas.
2. **Construir el DDL (Data Definition Language):** Escribir el script con las sentencias `CREATE TABLE`. Asegúrense de definir correctamente las Claves Primarias (PK), Claves Foráneas (FK) y los tipos de datos apropiados.
3. **Poblar la base de datos (DML):** Escribir un script con sentencias `INSERT` para generar datos de prueba (population). Cargar un mínimo de registros lógicos para poder interactuar con las tablas.
4. **Opcional**: Ingresar los registros por medio de la sentencia `COPY`.

---

### Módulo 2: Cacería de Errores en SQL

**Objetivo:** Desarrollar habilidades de *troubleshooting* identificando fallas críticas y violaciones de integridad en código ajeno.

**Dinámica:** Trabajo en equipos de 3 personas (Salas de Breakout).

**Tareas a realizar:**

1. **Analizar el script:** El instructor proveerá un archivo SQL que contiene 5 errores críticos intencionales (ej. un `UPDATE` sin cláusula `WHERE`, un `INSERT` que viola una restricción `CHECK`, y un `DROP TABLE` bloqueado por dependencias).
2. **Depurar el código:** Ejecutar el script, leer los mensajes del motor de base de datos y corregir la sintaxis para que corra exitosamente de principio a fin.
3. **Documentar el fallo:** Escribir un breve comentario explicando **por qué** fallaba originalmente cada instrucción.
4. **Puesta en común:** Regreso a la sala principal para la resolución y debate de las soluciones encontradas.

---

### Módulo 3: Simulacro de Transacciones Peligrosas

**Objetivo:** Comprender el uso de bloques transaccionales para garantizar la integridad de los datos ante errores del sistema.

**Dinámica:** Acompañar la demostración en vivo del instructor y replicar la solución.

**Tareas a realizar:**

1. **Análisis de la demo:** Observar qué ocurre a nivel de datos cuando un `UPDATE` sale mal durante la demostración en vivo.
2. **Implementar control transaccional:** Utilizar los comandos `BEGIN`, `COMMIT` y `ROLLBACK`.
3. **El desafío de la transferencia:** Escribir un script que simule una "transferencia de saldo" entre dos usuarios.
* *Regla de negocio:* Si el descuento de dinero del Usuario A es exitoso, pero el ingreso (o un `INSERT` de registro) en el Usuario B falla por un error, **toda la operación debe ser revertida automáticamente**.



---

### Módulo 4: Análisis de Casos de Estudio Reales

**Objetivo:** Debatir el impacto catastrófico que tienen las malas prácticas de SQL en aplicaciones de uso masivo.

**Tareas a realizar:**
Analizar en grupo los siguientes escenarios y proponer qué falló a nivel de base de datos y cómo debería solucionarse:

* **Caso Twitter (Impacto Estructural - DDL):** ¿Qué comportamiento tendría la plataforma si el campo correspondiente al `@handle` (nombre de usuario) no tuviera configurada la restricción `UNIQUE` en la base de datos?
* **Caso E-commerce (Error Operacional - DML):** Un administrador ejecuta una actualización masiva de precios en la base de datos de producción, pero olvida incluir la cláusula `WHERE`. Todo el catálogo de productos queda a $0.00. ¿Cómo se previene esto a nivel base de datos y permisos?
* **Caso Bancario (Integridad - Transacciones):** Ocurre una transferencia internacional. ¿Cómo garantizamos técnicamente que el débito en la cuenta de origen y el crédito en la cuenta de destino ocurran simultáneamente, evitando que el dinero se "pierda" si el servidor se apaga a la mitad del proceso?