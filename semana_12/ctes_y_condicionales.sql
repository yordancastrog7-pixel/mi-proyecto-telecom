-- ============================================
-- PROYECTO SEMANAL: CTEs y CASE WHEN
-- Semana 12 — Common Table Expressions + Condicionales
-- Dominio: Proyecto Telecom (Planes y Ventas)
-- ============================================

-- Desactivar restricciones temporalmente para limpieza
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS planes;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- ESTRUCTURA ADAPTADA A TELECOM
-- ============================================

-- Tabla Principal (Equivalente a items)
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    categoria_plan VARCHAR(50) NOT NULL
);

-- Tabla de Transacciones (Equivalente a transactions)
CREATE TABLE ventas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    plan_id INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    fecha_venta DATE NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);

-- ============================================
-- DATOS DE PRUEBA REALISTAS
-- ============================================

-- Insertamos 6 planes distribuidos en 3 categorías
INSERT INTO planes (nombre_plan, precio, categoria_plan) VALUES 
('Postpago Ultra 100GB', 80000.00, 'Postpago'),
('Postpago Básico 30GB', 45000.00, 'Postpago'),
('Prepago Joven 15GB', 25000.00, 'Prepago'),
('Prepago Minutos', 15000.00, 'Prepago'),
('Plan M2M Corporativo', 90000.00, 'Corporativo'),
('Plan GPS Flotas', 12000.00, 'Corporativo');

-- Insertamos 10 ventas distribuidas en el mes (transactions)
INSERT INTO ventas (plan_id, cantidad, fecha_venta) VALUES 
(1, 2, '2026-05-01'),
(1, 1, '2026-05-08'),
(2, 3, '2026-05-10'),
(3, 5, '2026-05-12'),
(3, 2, '2026-05-15'),
(4, 10, '2026-05-18'),
(5, 4, '2026-05-20'),
(5, 6, '2026-05-22'),
(6, 1, '2026-05-25'),
(2, 2, '2026-05-28');

-- ============================================
-- CONSULTA 1: CTE simple + CASE WHEN de clasificación
-- Objetivo: Clasificar cada plan según su precio en 3 bandas y mostrar total de ventas
-- ============================================

WITH planes_con_actividad AS (
    SELECT
        p.id,
        p.nombre_plan,
        p.precio,
        p.categoria_plan,
        COUNT(v.id) AS total_ventas
    FROM planes p
    LEFT JOIN ventas v ON v.plan_id = p.id
    GROUP BY p.id, p.nombre_plan, p.precio, p.categoria_plan
)
SELECT
    nombre_plan,
    precio,
    total_ventas,
    CASE
        WHEN precio >= 70000.00 THEN 'Premium'
        WHEN precio >= 30000.00 THEN 'Estándar'
        ELSE                   'Económico'
    END AS banda_precio
FROM planes_con_actividad
ORDER BY precio DESC;


-- ============================================
-- CONSULTA 2: Dos CTEs encadenados
-- Primer CTE: total de ventas (cantidad) por categoría
-- Segundo CTE: categorías cuyas ventas están por encima del promedio
-- Objetivo: Mostrar nombre y total vendido de las categorías top
-- ============================================

WITH ventas_por_categoria AS (
    SELECT
        p.categoria_plan,
        SUM(v.cantidad) AS total_vendido
    FROM planes p
    INNER JOIN ventas v ON v.plan_id = p.id
    GROUP BY p.categoria_plan
),
categorias_top AS (
    SELECT categoria_plan
    FROM ventas_por_categoria
    WHERE total_vendido > (SELECT AVG(total_vendido) FROM ventas_por_categoria)
)
SELECT
    vc.categoria_plan,
    vc.total_vendido
FROM ventas_por_categoria vc
WHERE vc.categoria_plan IN (SELECT categoria_plan FROM categorias_top)
ORDER BY vc.total_vendido DESC;

-- ============================================
-- CONSULTA 3: CTE + COUNT condicional por banda
-- Objetivo: Por cada categoría, contar cuántos planes hay en cada banda de precio
-- ============================================

WITH clasificados AS (
    SELECT
        nombre_plan,
        categoria_plan,
        precio,
        CASE
            WHEN precio >= 70000.00 THEN 'Premium'
            WHEN precio >= 30000.00 THEN 'Estándar'
            ELSE                   'Económico'
        END AS banda_precio
    FROM planes
)
SELECT
    categoria_plan,
    COUNT(CASE WHEN banda_precio = 'Premium'   THEN 1 END) AS cantidad_premium,
    COUNT(CASE WHEN banda_precio = 'Estándar'  THEN 1 END) AS cantidad_estandar,
    COUNT(CASE WHEN banda_precio = 'Económico' THEN 1 END) AS cantidad_economico
FROM clasificados
GROUP BY categoria_plan
ORDER BY categoria_plan;