-- Dominio: Proyecto Telecom (Planes y Líneas)
-- ============================================

-- Desactivar restricciones temporalmente para limpieza
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- ESTRUCTURA ADAPTADA A TELECOM
-- ============================================

-- Tabla Principal (Equivalente a main_items)
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    tipo_plan VARCHAR(50) NOT NULL -- Equivalente a 'category'
);

-- Tabla Hija (Equivalente a child_records)
CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    plan_id INT NOT NULL,
    numero_celular VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);

-- ============================================
-- DATOS DE PRUEBA REALISTAS
-- ============================================

-- Insertamos Planes (Incluyendo uno sin líneas asociadas)
INSERT INTO planes (nombre_plan, precio, tipo_plan) VALUES 
('Postpago Ultra 100GB', 75000.00, 'Postpago'),
('Postpago Básico 30GB', 45000.00, 'Postpago'),
('Prepago Joven 15GB', 25000.00, 'Prepago'),
('Prepago Minutos', 15000.00, 'Prepago'),
('Plan M2M IoT', 10000.00, 'Corporativo'); -- Este será el plan SIN líneas (para NOT EXISTS)

-- Insertamos Líneas (child_records)
INSERT INTO lineas (plan_id, numero_celular) VALUES 
(1, '3001112233'),
(1, '3104445566'),
(1, '3207778899'),
(2, '3159990011'),
(3, '3012223344'),
(4, '3115556677');



-- CONSULTA 1: Subquery escalar en WHERE
-- Objetivo: Mostrar los planes cuyo precio supera el precio promedio de su propio tipo (Prepago/Postpago)
-- ============================================

SELECT
    nombre_plan,
    precio,
    tipo_plan
FROM planes p
WHERE precio > (
    SELECT AVG(p2.precio)
    FROM planes p2
    WHERE p2.tipo_plan = p.tipo_plan
)
ORDER BY tipo_plan, precio DESC;


-- ============================================
-- CONSULTA 2: Subquery escalar en SELECT
-- Objetivo: Mostrar el precio promedio global de todos los planes junto a cada plan individual
-- ============================================

SELECT
    nombre_plan,
    precio,
    ROUND((SELECT AVG(precio) FROM planes), 2) AS promedio_global
FROM planes
ORDER BY precio DESC;



-- ============================================
-- CONSULTA 3: NOT EXISTS — items sin actividad
-- Objetivo: Mostrar planes que NO tienen ninguna línea de celular asociada
-- ============================================

SELECT
    nombre_plan AS plan_sin_lineas
FROM planes p
WHERE NOT EXISTS (
    SELECT 1
    FROM lineas l
    WHERE l.plan_id = p.id
);


-- ============================================
-- CONSULTA 4: Tabla derivada en FROM
-- Objetivo: Mostrar tipos de planes que tienen más de 2 líneas activas en total
-- ============================================

SELECT
    estadisticas_planes.tipo_plan,
    estadisticas_planes.total_lineas
FROM (
    SELECT
        p.tipo_plan,
        COUNT(l.id) AS total_lineas
    FROM planes p
    LEFT JOIN lineas l ON l.plan_id = p.id
    GROUP BY p.tipo_plan
) AS estadisticas_planes
WHERE estadisticas_planes.total_lineas > 2
ORDER BY estadisticas_planes.total_lineas DESC;