-- ============================================
-- PROYECTO SEMANAL: Jerarquías con CTEs Recursivas
-- Dominio: Proyecto Telecom (Categorías de Productos)
-- ============================================

-- Desactivar restricciones temporalmente para limpieza
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS categorias_productos;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- ESTRUCTURA ADAPTADA A TELECOM
-- ============================================

-- Tabla auto-referencial (Equivalente a nodes)
CREATE TABLE categorias_productos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    categoria_padre_id INT, -- Equivalente a parent_id
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias_productos(id)
);

-- ============================================
-- DATOS DE PRUEBA (3 NIVELES DE PROFUNDIDAD)
-- ============================================

-- Nivel 1: Nodo raíz (parent_id es NULL)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(1, 'Catálogo Móvil', NULL);

-- Nivel 2: Nodos hijos (su parent_id es 1)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(2, 'Planes Postpago', 1),
(3, 'Planes Prepago', 1);

-- Nivel 3: Nodos nietos (su parent_id es 2 o 3)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(4, 'Postpago Ultra 100GB', 2),
(5, 'Postpago Básico 30GB', 2),
(6, 'Prepago Joven 15GB', 3),
(7, 'Prepago Minutos', 3);

SELECT
    c.id,
    c.nombre AS plan_final_sin_hijos
FROM categorias_productos c
WHERE NOT EXISTS (
    SELECT 1
    FROM categorias_productos sub
    WHERE sub.categoria_padre_id = c.id
)
ORDER BY c.nombre;