# SQL & PostgreSQL: Desde los Fundamentos hasta el Análisis Avanzado
> **Curso Académico · Coderhouse**

---

## Filosofía del Repositorio
Este repositorio actúa como un **artefacto vivo** de aprendizaje. No contiene únicamente código estructurado; documenta la transición cognitiva desde el pensamiento lineal plano (hojas de cálculo tradicionales) hacia el modelado relacional riguroso, la optimización física de consultas y la ingeniería de datos moderna [227, 238, 905].

---

## Perfil del Egresado
El contenido está arquitectónicamente optimizado para los siguientes roles de la industria de la tecnología [223]:
*   **Data Engineer / Analytics Engineer**
*   **Business Intelligence (BI) Analyst**
*   **Full Stack Developer**

---

## Mapa de Ruta: Estructura del Curso

El programa académico avanza de manera progresiva y secuencial, garantizando que cada bloque construya sobre el anterior [226, 312, 401, 477, 557, 655, 735, 847]:

```
[M1: Entorno] ──> [M2: Estructuras] ──> [M3: Consultas] ──> [M4: Relaciones]
                                                                   │
[M8: Capstone] <── [M7: Modern SQL] <── [M6: Rendimiento] <── [M5: Avanzado]
```

### [Módulo 1: Fundamentos y Configuración del Entorno](https://github.com/)
*   **Enfoque**: Diagnóstico e instalación del ecosistema cliente-servidor de PostgreSQL [213, 301, 305].
*   **Hitos de aprendizaje**: Modelo Entidad-Relación (ER), cardinalidades (1:1, 1:N, N:M), normalización básica (1NF, 2NF) y el comando `CREATE DATABASE` [214, 216, 268, 271, 272].
*   **Herramientas**: pgAdmin 4, DBeaver, psql CLI [213, 247].

### [Módulo 2: Diseño y Manipulación de Datos (DDL & DML)](https://github.com/)
*   **Enfoque**: Diseño y modificación de esquemas robustos aplicando restricciones estrictas [312, 322].
*   **Hitos de aprendizaje**: Definición de tablas (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`), restricciones de integridad (`PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, `NOT NULL`, `UNIQUE`) e ingesta manual y masiva (`INSERT`, `COPY` de archivos CSV) [219, 220, 316, 317, 328, 351, 363].
*   **Seguridad**: Control de transacciones robustas mediante atomicidad (`BEGIN`, `COMMIT`, `ROLLBACK`) [221, 364].

### [Módulo 3: Consultas Esenciales y Filtrado de Datos](https://github.com/)
*   **Enfoque**: Extracción precisa y depuración de colecciones en tablas individuales [401, 402].
*   **Hitos de aprendizaje**: Filtros lógicos complejos (`WHERE`, `AND`, `OR`, `NOT`, `LIKE` / `ILIKE`), ordenamiento y paginación (`ORDER BY`, `LIMIT`, `OFFSET`) y gestión de valores ausentes (`IS NULL`, `COALESCE`) [221, 421, 423, 429, 430, 431, 445].
*   **Métricas**: Agregaciones directas con `COUNT`, `SUM`, `AVG`, `MIN` y `MAX` [438].

### [Módulo 4: Relaciones, JOINS y Agrupaciones Avanzadas](https://github.com/)
*   **Enfoque**: Conexión de múltiples orígenes y consolidación de conjuntos de datos fragmentados [477, 478].
*   **Hitos de aprendizaje**: Álgebra relacional de uniones (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL OUTER JOIN`), resolución de ambigüedades mediante alias, segmentación (`GROUP BY`) y filtrado posterior a la agrupación (`HAVING`) [480, 496, 501, 506, 511].
*   **Multicapa**: Subconsultas anidadas y teoría de conjuntos (`UNION`, `INTERSECT`, `EXCEPT`) [520, 523, 524].

### [Módulo 5: SQL Avanzado para Análisis de Datos](https://github.com/)
*   **Enfoque**: Procesamiento analítico complejo y reestructuración lógica secuencial [557, 558].
*   **Hitos de aprendizaje**: Expresiones de Tabla Comunes (`WITH` CTEs), CTEs recursivas para estructuras jerárquicas y funciones de ventana para clasificaciones competitivas y acumulados (`ROW_NUMBER`, `RANK`, `DENSE_RANK`, `PARTITION BY`, `SUM() OVER`) [562, 567, 582, 585, 605].
*   **Lógica temporal**: Extracción de componentes de fecha con `EXTRACT`, intervalos y lógica condicional sobre la marcha con `CASE WHEN` [607, 609, 613].

### [Módulo 6: Optimización y Rendimiento en PostgreSQL](https://github.com/)
*   **Enfoque**: Diagnóstico e ingeniería de rendimiento interno para consultas a gran escala [655, 656].
*   **Hitos de aprendizaje**: El planificador secreto (`EXPLAIN`, `EXPLAIN ANALYZE`), ineficiencias de lectura (*Sequential Scan* vs *Index Scan*), control de concurrencia multiversión (MVCC) y el proceso físico de mantenimiento (`VACUUM`) [659, 664, 683, 684, 831].
*   **Indexación**: Estructuras físicas B-Tree, Hash e Índices Invertidos Generalizados (GIN) [692, 694, 696].
*   **Caché**: Implementación de Vistas Materializadas para reportes analíticos masivos [723, 724].

### [Módulo 7: PostgreSQL Moderno: JSONB y Extensiones AI](https://github.com/)
*   **Enfoque**: Extensibilidad, almacenamiento híbrido de documentos e integración de inteligencia artificial [735, 782, 783].
*   **Hitos de aprendizaje**: Manipulación de datos semiestructurados con `JSONB` en formato binario descompuesto, operadores de extracción (`->`, `->>`) e indexación GIN de claves internas [740, 747, 821, 822].
*   **Búsqueda avanzada**: Búsqueda de Texto Completo (*Full-Text Search*) nativa con reducción lingüística (`to_tsvector`, `to_tsquery`, `@@`, `ts_rank`) y almacenamiento de embeddings vectoriales para búsquedas semánticas con la extensión `pgvector` [763, 767, 768, 769, 771, 793].
*   **Gobernanza**: Roles sin login, herencia de privilegios y control de acceso basado en roles (RBAC) bajo el principio de menor privilegio [802, 803, 805, 808].

### [Módulo 8: Proyecto Final Capstone (Análisis Exploratorio de Datos)](https://github.com/)
*   **Enfoque**: Simulación completa del flujo de trabajo de un Analista o Ingeniero de Datos senior [848, 872].
*   **Hitos de aprendizaje**: Definición de infraestructuras limpias, procesos de extracción, transformación y carga (ETL), limpieza estricta de outliers/nulos y comunicación de insights estratégicos accionables para la toma de decisiones [860, 862, 863, 873].

---

## Estructura Recomendada del Repositorio

Para mantener un orden metodológico y profesional, se estructura el espacio de trabajo en las siguientes carpetas y archivos clave [872]:

```bash
├── .gitignore
├── README.md                           <-- Este documento descriptivo y técnico
├── capstone_project/                   <-- Entregable de la integración de final de carrera
│   ├── estructura.sql                  <-- Scripts de DDL de creación de base de datos y carga [872]
│   ├── analisis.sql                    <-- Consultas analíticas, subconsultas y window functions [872]
│   └── README.md                       <-- Interpretación de negocio de los datos limpios [872]
├── modulo_1_fundamentos/               <-- Diagramas ER, laboratorios de instalación y meta-comandos [246, 292]
├── modulo_2_ddl_dml/                   <-- Scripts SQL de creación de tablas, llaves y transacciones [334, 381]
├── modulo_5_analisis_avanzado/          <-- Reportes avanzados estructurados con CTEs y ventanas [578, 634]
└── modulo_7_moderno/                   <-- Prácticas con campos JSONB, FTS y esquemas de roles (RBAC) [761, 816]
```

---

## Conectividad Local de Referencia

Para interactuar con la base de datos a través de cualquier interfaz gráfica (DBeaver, pgAdmin) o entorno de programación externa (Python, BI tools), los parámetros de comunicación son [214, 250]:

*   **Host**: `localhost` (para conexiones locales) [214, 250]
*   **Puerto**: `5432` (puerto predeterminado del motor) [213, 214, 250]
*   **Base de Datos**: `capstone_project` (o `postgres` para acceso maestro inicial) [214, 250, 251]
*   **Usuario**: `postgres` (o tu usuario personalizado con rol heredado) [214, 250, 805]
*   **Contraseña**: *La contraseña de administrador configurada durante la instalación* [214, 250]

---

## Convenciones y Buenas Prácticas del Código
*   **Sintaxis**: Escribir todas las palabras clave y comandos reservados de SQL en **MAYÚSCULAS** (`SELECT`, `FROM`, `WHERE`) [405, 415].
*   **Nomenclatura**: Nombrar tablas y campos de forma consistente en **minúsculas** y con estilo **snake_case** (ej. `id_cliente`) [276, 320]. Las entidades lógicas de diseño deben ir siempre en **singular** [276].
*   **Seguridad DML**: Nunca ejecutar un `UPDATE` o `DELETE` sin un filtro `WHERE` asociado [221, 361, 363]. Utilizar siempre bloques transaccionales manuales (`BEGIN ... COMMIT / ROLLBACK`) para modificaciones masivas [221, 364].
*   **Rendimiento**: Evitar el uso descontrolado de `SELECT *` en entornos de producción y automatización [407, 415]. Especificar explícitamente las columnas necesarias para no sobrecargar el Buffer Pool [407, 663].
