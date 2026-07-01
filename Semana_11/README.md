# Semana 11: Subconsultas (Subqueries)

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)

---

## 1. Objetivos y Alcance del Módulo

El propósito de esta semana es aprender a usar **Subconsultas**. En palabras sencillas, una subconsulta es "hacer una pregunta dentro de otra pregunta". Nos sirve para calcular un dato en el momento y luego usar ese dato para filtrar nuestra consulta principal.

* **Subconsulta Escalar:** Es una consulta pequeña que devuelve un único valor (como un promedio o un total). Lo usamos para comparar o para mostrarlo como una columna extra.
* **Uso de NOT EXISTS:** Una forma muy eficiente de buscar registros "huérfanos" (por ejemplo, planes que nadie ha comprado o que no tienen líneas activas).
* **Tabla Derivada (en el FROM):** Consiste en hacer una consulta y tratar el resultado de esa consulta como si fuera una tabla real y temporal, para luego volver a consultar sobre ella.

---

## 2. Adaptación del Modelo de Datos

Para practicar estos conceptos, creamos dos tablas en nuestro sistema de telecomunicaciones:

* **Tabla Principal (`planes`):** Guarda nuestro catálogo de productos (ej. Prepago Joven, Postpago Ultra).
* **Tabla Hija (`lineas`):** Guarda los números de celular que los clientes han activado. Cada línea está obligatoriamente conectada a un plan.

---

## 3. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, los códigos utilizados esta semana, explicados paso a paso para facilitar su estudio.

### A. Inicialización y Creación de la Estructura

Creamos las tablas asegurando que la tabla `lineas` esté conectada a la tabla `planes` mediante una llave foránea (`plan_id`).

```sql
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    tipo_plan VARCHAR(50) NOT NULL 
);

CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    plan_id INT NOT NULL,
    numero_celular VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);

```
### B.Inserción de Datos (Preparando el escenario)

Agregamos planes de prueba y les asignamos números de celular. Nota importante: El "Plan M2M IoT" se insertó a propósito sin ninguna línea asignada para poder probar la búsqueda de elementos vacíos más adelante.

```sql
INSERT INTO planes (nombre_plan, precio, tipo_plan) VALUES 
('Postpago Ultra 100GB', 75000.00, 'Postpago'),
('Postpago Básico 30GB', 45000.00, 'Postpago'),
('Prepago Joven 15GB', 25000.00, 'Prepago'),
('Prepago Minutos', 15000.00, 'Prepago'),
('Plan M2M IoT', 10000.00, 'Corporativo'); 

INSERT INTO lineas (plan_id, numero_celular) VALUES 
(1, '3001112233'),
(1, '3104445566'),
(1, '3207778899'),
(2, '3159990011'),
(3, '3012223344'),
(4, '3115556677');

```

### C.Consultas Escalares (Un solo valor)

La primera consulta calcula el promedio de precio en secreto y solo nos muestra los planes que son más caros que ese promedio. La segunda consulta calcula el promedio general y lo pega al lado de cada plan para que podamos comparar visualmente.

```sql
-- CONSULTA 1: Filtrar usando un cálculo dinámico
SELECT nombre_plan, precio, tipo_plan
FROM planes p
WHERE precio > (
    SELECT AVG(p2.precio)
    FROM planes p2
    WHERE p2.tipo_plan = p.tipo_plan
)
ORDER BY tipo_plan, precio DESC;

-- CONSULTA 2: Mostrar un cálculo global como columna
SELECT nombre_plan, precio,
    ROUND((SELECT AVG(precio) FROM planes), 2) AS promedio_global
FROM planes
ORDER BY precio DESC;

```
### D. Búsqueda de Huérfanos y Tablas Derivadas

La consulta 3 rastrea qué planes no tienen actividad buscando en la tabla hija. La consulta 4 primero cuenta cuántas líneas tiene cada tipo de plan (creando una "tabla temporal" en memoria) y luego filtra para mostrar solo los tipos muy populares (con más de 2 líneas).

```sql
-- CONSULTA 3: Encontrar el plan sin ventas (NOT EXISTS)
SELECT nombre_plan AS plan_sin_lineas
FROM planes p
WHERE NOT EXISTS (
    SELECT 1
    FROM lineas l
    WHERE l.plan_id = p.id
);

-- CONSULTA 4: Convertir un resultado en una tabla nueva (Tabla derivada)
SELECT estadisticas_planes.tipo_plan, estadisticas_planes.total_lineas
FROM (
    SELECT p.tipo_plan, COUNT(l.id) AS total_lineas
    FROM planes p
    LEFT JOIN lineas l ON l.plan_id = p.id
    GROUP BY p.tipo_plan
) AS estadisticas_planes
WHERE estadisticas_planes.total_lineas > 2
ORDER BY estadisticas_planes.total_lineas DESC;

```