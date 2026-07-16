# Resumen del Módulo 1: Fundamentos y Configuración del Entorno

El primer módulo se enfoca en **instalar el entorno de trabajo** y comprender tanto la **estructura de las bases de datos relacionales** como el **modelo entidad-relación**. 

---

### 1. El Problema de los Archivos Tradicionales y la Solución RDBMS
Trabajar con archivos planos (como Excel) para grandes volúmenes de datos genera tres inconvenientes graves:
*   **Redundancia:** Repetición innecesaria de información.
*   **Inconsistencia:** Datos contradictorios debido a modificaciones parciales o errores de escritura.
*   **Acceso Concurrente:** Riesgo de corrupción si varios empleados actualizan los datos al mismo tiempo.

Los **Sistemas de Gestión de Bases de Datos Relacionales (RDBMS)** resuelven estos problemas conectando tablas de forma lógica y asegurando la integridad, escalabilidad, seguridad y concurrencia bajo el lenguaje estándar **SQL**.

---

### 2. Bloques de Construcción de una Base de Datos Relacional
*   **Tabla (Entidad):** El objeto principal sobre el que guardamos información.
*   **Columna (Atributo o Campo):** Define qué característica o tipo de dato se almacena.
*   **Fila (Registro o Tupla):** Una entrada individual única en la tabla.
*   **Clave Primaria (Primary Key - PK):** Un identificador único e irrepetible para cada fila, que jamás puede ser nulo. Al definirla, PostgreSQL genera automáticamente un **Índice** para acelerar las búsquedas.
*   **Clave Foránea (Foreign Key - FK):** Una columna que apunta a la Clave Primaria de otra tabla para conectarlas físicamente y garantizar la **integridad referencial**.

---

### 3. El Ecosistema de PostgreSQL e Instalación
El entorno se compone de una arquitectura **Cliente-Servidor**:
1.  **PostgreSQL (El Servidor):** Es el motor de base de datos que corre en segundo plano procesando peticiones y administrando el disco. El usuario administrador por defecto es `postgres` y su puerto estándar de escucha es el `5432`.
2.  **pgAdmin 4 o DBeaver (El Cliente):** Son las interfaces gráficas que usamos para comunicarnos de manera amigable con el servidor.

Para conectar cualquier herramienta a la base de datos se requieren **5 parámetros fundamentales**: *Host* (`localhost` para entornos locales), *Puerto* (`5432`), *Base de Datos* (`postgres` por defecto), *Usuario* (`postgres`) y la *Contraseña* configurada en la instalación.

#### Herramientas de Interacción:
*   **psql CLI:** Una interfaz de línea de comandos ágil y universal. Utiliza meta-comandos especiales que inician con `\`:
    *   `\l` : Lista todas las bases de datos.
    *   `\c nombre_db` : Conecta a una base de datos específica.
    *   `\dt` : Lista las tablas disponibles.
    *   `\q` : Sale de la terminal de psql.
*   **Sentencia `CREATE DATABASE`:** Comando del lenguaje DDL utilizado para reservar un nuevo espacio de trabajo en disco.

---

### 4. Tipos de Datos Fundamentales
PostgreSQL es estricto con los tipos de datos para asegurar el rendimiento y la precisión de los análisis:
*   **Cadenas de Texto:** `VARCHAR(n)` para texto variable con límite y `TEXT` para párrafos largos sin límite predefinido.
*   **Numéricos:** 
    *   `INTEGER` para números enteros.
    *   `NUMERIC(p, s)` para decimales con precisión exacta, siendo la **regla de oro para almacenar dinero** para evitar errores de redondeo en cálculos financieros (típicos de tipos aproximados como `FLOAT` o `REAL`).
    *   `SERIAL` para enteros autoincrementales automáticos, ideal para generar identificadores de forma transparente.
*   **Lógicos y Temporales:** `BOOLEAN` (valores `TRUE` / `FALSE`) y `DATE` (formato Año-Mes-Día).

---

### 5. Modelo Entidad-Relación (ER) y Normalización
Antes de codificar, es indispensable diseñar un esquema o plano arquitectónico.
*   **Componentes ER:** **Entidades** (rectángulos, conceptos en singular), **Atributos** (elipses/círculos, características de la entidad), **Relaciones** (rombos, acciones que las unen) y **Cardinalidad**.
*   **Tipos de Cardinalidad:** Uno a Uno (1:1), Uno a Muchos (1:N, la más común) y Muchos a Muchos (N:M, que requiere una **tabla intermedia** para poder implementarse en SQL).

#### Reglas de Normalización Básica:
La normalización organiza las columnas para reducir la duplicación y mejorar la integridad:
1.  **Primera Forma Normal (1NF - Cero grupos repetidos):** Cada celda debe contener un valor único (atómico), no debe haber columnas repetidas (como `Telefono1`, `Telefono2`), y debe existir una clave primaria única.
2.  **Segunda Forma Normal (2NF - Dependencia total):** Debe cumplir con la 1NF y todos los datos de la fila deben depender exclusivamente de la Clave Primaria completa, eliminando dependencias parciales mediante la separación de la información en tablas lógicas conectadas por IDs.

#### Buenas Prácticas de Diseño:
*   Usar nombres consistentes en minúsculas y separados por guiones bajos (**snake_case**).
*   Nombrar las entidades en **singular** (ej. `cliente` en lugar de `clientes`).
*   Dibujar un borrador del esquema antes de empezar a programar en SQL.


### Downloads
- [Postgresql](https://www.postgresql.org/download/)
- [Dbeaver](https://dbeaver.io/download/)

### Docker container image

```dockerfile
# docker-compose.yml
services:
  db:
    image: pgvector/pgvector:pg17
    container_name: pgvector_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: coderhouse-database
    ports:
      - "5432:5432"
    volumes:
      - pgvector_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

volumes:
  pgvector_data:
```

```sql
-- init.sql
CREATE EXTENSION IF NOT EXISTS vector;
```

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/coderhouse-database
```







