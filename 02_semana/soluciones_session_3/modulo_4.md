### Análisis de Casos de Estudio Reales

#### Caso Twitter (Impacto Estructural - DDL)

**¿Qué falló a nivel de base de datos?**
La ausencia de la restricción `UNIQUE` en la columna del handle (nombre de usuario) permite la duplicación de datos.

**Impacto catastrófico en la plataforma:**

* **Caída del enrutamiento:** Si tres usuarios logran registrar el handle `@juan`, el sistema de base de datos le asignará a cada uno un `id_usuario` distinto (ej. 10, 45, 102).
* **Colapso de menciones y mensajes:** Cuando alguien tuitea "Hola @juan", el backend (la capa lógica) hace un `SELECT id_usuario FROM usuarios WHERE handle = '@juan'`. Al recibir tres resultados en lugar de uno, la aplicación no sabría a quién notificar, a quién enviarle un mensaje directo o qué perfil mostrar al hacer clic.
* **Fallo de Autenticación:** Sería imposible iniciar sesión utilizando el nombre de usuario.

**Solución:**
Aplicar la restricción al crear la tabla o mediante un `ALTER TABLE`. Como beneficio adicional, el motor de base de datos crea automáticamente un índice (Index) sobre las columnas `UNIQUE`, lo que acelera masivamente las búsquedas de perfiles.

```sql
ALTER TABLE usuarios ADD CONSTRAINT unique_handle UNIQUE (handle);
```

---

#### Caso E-commerce (Error Operacional - DML)

**¿Qué falló a nivel de base de datos?**
Un error humano crítico: ejecutar un comando de modificación de datos (`UPDATE` o `DELETE`) directamente en el entorno de Producción sin la cláusula limitante `WHERE`, afectando a la totalidad de los registros.

**Impacto catastrófico en la plataforma:**
Todos los productos del catálogo pasan a costar $0.00. Si esto ocurre automatizado o con alto tráfico, la empresa asume pérdidas financieras masivas, problemas legales por cancelar compras ya facturadas y un daño reputacional severo.

**Solución y Prevención:**
Aquí el debate debe centrarse en que **el error humano siempre va a existir**, por lo que la base de datos debe estar configurada para mitigarlo.

1. **Principio de Menor Privilegio (Gestión de Roles):** Ningún usuario, ni siquiera los administradores, debería conectarse a la base de datos de Producción con permisos de superusuario para tareas diarias. Se deben crear roles que solo permitan ejecutar procedimientos almacenados predefinidos o vistas, bloqueando el acceso directo a las tablas.
2. **Configuraciones de Seguridad del Motor (Safe Updates):** Motores como MySQL tienen modos (ej. `sql_safe_updates = 1`) que bloquean cualquier `UPDATE` o `DELETE` que no utilice una clave primaria en su cláusula `WHERE`.
3. **Auditoría y Backups Continuos:** Implementar copias de seguridad de recuperación en un punto en el tiempo (Point-in-Time Recovery - PITR). Esto permite "rebobinar" la base de datos al minuto exacto anterior a la ejecución del comando erróneo.

---

#### Caso Bancario (Integridad - Transacciones)

**¿Qué falló a nivel de base de datos?**
Este es el clásico problema de las operaciones de múltiples pasos. Ocurre una caída del servidor (por corte de energía o fallo de hardware) exactamente después de descontar el dinero de la Cuenta A, pero milisegundos antes de sumarlo en la Cuenta B.

**Impacto catastrófico en la plataforma:**
Destrucción de la integridad de los datos. El dinero se "esfuma" del sistema. Si el fallo fuera a la inversa (se suma primero y luego se intenta descontar), se estaría creando dinero de la nada.

**Solución:**
El cumplimiento estricto de las propiedades **ACID** de las bases de datos relacionales, específicamente la **A (Atomicidad)** y la **D (Durabilidad)**.

* **Implementación técnica:** Toda la operación se envuelve en un bloque `BEGIN` y `COMMIT`.
* **Mecanismo de rescate:** Las bases de datos transaccionales utilizan un archivo llamado **WAL (Write-Ahead Log)**. Cuando el servidor recupera la energía y se reinicia, el motor lee el WAL, detecta que había una transacción que empezó (`BEGIN`) pero nunca recibió la orden de finalización (`COMMIT`). Automáticamente, el motor ejecuta un `ROLLBACK` interno, devolviendo el dinero a la Cuenta A antes de permitir nuevas conexiones, garantizando que el sistema vuelva a su estado consistente.
