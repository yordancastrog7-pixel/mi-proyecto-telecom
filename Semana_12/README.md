# Semana 12: Expresiones de Tabla Comunes (CTEs) y Condicionales

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)

---

## 1. Objetivos y Alcance del Módulo

El propósito de esta semana es aprender a organizar consultas complejas paso a paso y a crear reglas de clasificación "al vuelo":

* **CTEs (Common Table Expressions):** En palabras sencillas, es como crear una "tabla temporal" o un "borrador" en la memoria antes de hacer la consulta final. Primero calculamos algo complejo, le ponemos un nombre (el CTE), y luego le hacemos un simple `SELECT` a ese borrador. Esto hace que el código sea mucho más limpio y fácil de leer.
* **CTEs Encadenados:** Es la capacidad de crear un borrador y luego usarlo para crear un segundo borrador. Nos sirve para ir filtrando la información en varias etapas lógicas.
* **Condicionales (CASE WHEN):** Funciona como un tomador de decisiones. Nos permite evaluar el valor de una columna y asignarle una etiqueta nueva (por ejemplo, si el precio de un plan supera los 70.000, etiquetarlo dinámicamente como 'Premium').

---

## 2. Adaptación del Modelo de Datos

Para practicar estos conceptos, creamos dos tablas que simulan la operación comercial de la empresa de telecomunicaciones:

* **Tabla Principal (`planes`):** Nuestro catálogo de productos, que guarda el nombre del plan, la categoría (Prepago, Postpago, Corporativo) y su precio.
* **Tabla de Transacciones (`ventas`):** El registro histórico de cada venta, indicando qué plan se vendió, qué cantidad de líneas se activaron y en qué fecha.

---

## 3. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, los códigos utilizados esta semana, explicados de forma sencilla para facilitar su estudio y repaso.

### A. Inicialización y Creación de la Estructura

Creamos el catálogo de planes y la tabla de ventas, asegurándonos de que cada venta esté enlazada a un plan existente mediante la llave foránea `plan_id`.

```sql
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS planes;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    categoria_plan VARCHAR(50) NOT NULL
);

CREATE TABLE ventas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    plan_id INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    fecha_venta DATE NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);
```
### B.Inserción de Datos (Preparando el escenario)

Agregamos 6 planes distribuidos en 3 categorías diferentes y registramos 10 ventas en distintas fechas para tener volumen de datos que analizar.

```sql
INSERT INTO planes (nombre_plan, precio, categoria_plan) VALUES 
('Postpago Ultra 100GB', 80000.00, 'Postpago'),
('Postpago Básico 30GB', 45000.00, 'Postpago'),
('Prepago Joven 15GB', 25000.00, 'Prepago'),
('Prepago Minutos', 15000.00, 'Prepago'),
('Plan M2M Corporativo', 90000.00, 'Corporativo'),
('Plan GPS Flotas', 12000.00, 'Corporativo');

INSERT INTO ventas (plan_id, cantidad, fecha_venta) VALUES 
(1, 2, '2026-05-01'), (1, 1, '2026-05-08'),
(2, 3, '2026-05-10'), (3, 5, '2026-05-12'),
(3, 2, '2026-05-15'), (4, 10, '2026-05-18'),
(5, 4, '2026-05-20'), (5, 6, '2026-05-22'),
(6, 1, '2026-05-25'), (2, 2, '2026-05-28');
```
### C. CTE Simple y Condicionales (Clasificación de precios)
Aquí creamos un "borrador" llamado planes_con_actividad que junta los planes con su total de ventas. Luego, en la consulta final, usamos un CASE WHEN para revisar el precio y ponerle a cada plan una medalla: Premium, Estándar o Económico.

```sql
WITH planes_con_actividad AS (
    SELECT
        p.id, p.nombre_plan, p.precio, p.categoria_plan,
        COUNT(v.id) AS total_ventas
    FROM planes p
    LEFT JOIN ventas v ON v.plan_id = p.id
    GROUP BY p.id, p.nombre_plan, p.precio, p.categoria_plan
)
SELECT nombre_plan, precio, total_ventas,
    CASE
        WHEN precio >= 70000.00 THEN 'Premium'
        WHEN precio >= 30000.00 THEN 'Estándar'
        ELSE                   'Económico'
    END AS banda_precio
FROM planes_con_actividad
ORDER BY precio DESC;
```

### D. CTEs Encadenados (Filtrar a los mejores)
Este es un proceso de dos pasos. Borrador 1 (ventas_por_categoria): suma cuántas líneas vendió cada categoría en total. Borrador 2 (categorias_top): mira el Borrador 1 y saca solo las categorías que vendieron por encima del promedio. Al final, solo mostramos a las ganadoras.

```sql
WITH ventas_por_categoria AS (
    SELECT p.categoria_plan, SUM(v.cantidad) AS total_vendido
    FROM planes p
    INNER JOIN ventas v ON v.plan_id = p.id
    GROUP BY p.categoria_plan
),
categorias_top AS (
    SELECT categoria_plan
    FROM ventas_por_categoria
    WHERE total_vendido > (SELECT AVG(total_vendido) FROM ventas_por_categoria)
)
SELECT vc.categoria_plan, vc.total_vendido
FROM ventas_por_categoria vc
WHERE vc.categoria_plan IN (SELECT categoria_plan FROM categorias_top)
ORDER BY vc.total_vendido DESC;
```
### E. CTE con Conteo Condicional
Primero clasificamos todos nuestros planes en Premium, Estándar o Económico. Luego, agrupamos por categoría (Prepago, Postpago, Corporativo) y usamos COUNT(CASE WHEN...) para contar cuántos planes de cada tipo exacto tenemos dentro de cada categoría.

```sql
WITH clasificados AS (
    SELECT nombre_plan, categoria_plan, precio,
        CASE
            WHEN precio >= 70000.00 THEN 'Premium'
            WHEN precio >= 30000.00 THEN 'Estándar'
            ELSE                   'Económico'
        END AS banda_precio
    FROM planes
)
SELECT categoria_plan,
    COUNT(CASE WHEN banda_precio = 'Premium'   THEN 1 END) AS cantidad_premium,
    COUNT(CASE WHEN banda_precio = 'Estándar'  THEN 1 END) AS cantidad_estandar,
    COUNT(CASE WHEN banda_precio = 'Económico' THEN 1 END) AS cantidad_economico
FROM clasificados
GROUP BY categoria_plan
ORDER BY categoria_plan;
```
