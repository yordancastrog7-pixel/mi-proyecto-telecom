-- ============================================
-- PROYECTO SEMANAL: SELF JOIN en tu dominio
-- Semana 10 — Jerarquías y Auto-referencias
-- ============================================

-- Preparación del entorno MySQL
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS categorias_planes;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- PARTE 1: CREACIÓN DE LA TABLA AUTO-REFERENCIAL
-- ============================================
-- La columna 'categoria_padre_id' apunta a la misma tabla 'categorias_planes'
CREATE TABLE categorias_planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    categoria_padre_id INT,
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias_planes(id)
);

-- ============================================
-- PARTE 2: INSERCIÓN DE DATOS JERÁRQUICOS
-- ============================================

-- 1. Registro RAÍZ (Nivel 0 - No tiene padre, su parent_id es NULL)
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) VALUES 
    (1, 'Conectividad Móvil', NULL);

-- 2. Registros HIJOS (Nivel 1 - Su padre es la raíz [ID 1])
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) VALUES 
    (2, 'Líneas Postpago', 1),
    (3, 'Líneas Prepago', 1),
    (4, 'Paquetes de Datos', 1);

-- 3. Registros NIETOS (Nivel 2 - Sus padres son los registros del Nivel 1)
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) VALUES 
    (5, 'Postpago Plus 50GB', 2),
    (6, 'Prepago Básico 5GB', 3);


-- ============================================
-- PARTE 3: CONSULTAS DE JERARQUÍA (SELF JOIN)
-- ============================================

-- CONSULTA 1: SELF JOIN básico (INNER JOIN)
-- Muestra item hijo y su padre. Oculta la Raíz porque no tiene padre (es NULL).
SELECT
    hijo.nombre AS subcategoria,
    padre.nombre AS categoria_padre
FROM categorias_planes hijo
INNER JOIN categorias_planes padre ON hijo.categoria_padre_id = padre.id;


-- CONSULTA 2: Incluir la raíz con LEFT JOIN
-- Muestra todos los elementos. Si no tiene padre (Raíz), le pone la etiqueta 'Categoría Principal'.
SELECT
    hijo.nombre AS categoria,
    COALESCE(padre.nombre, '--- Categoría Principal (Raíz) ---') AS pertenece_a
FROM categorias_planes hijo
LEFT JOIN categorias_planes padre ON hijo.categoria_padre_id = padre.id
ORDER BY pertenece_a, categoria;


-- CONSULTA 3: Contar hijos por padre
-- Muestra cuántas subcategorías dependen de cada categoría mayor.
SELECT
    padre.nombre AS categoria_padre,
    COUNT(hijo.id) AS total_subcategorias
FROM categorias_planes padre
LEFT JOIN categorias_planes hijo ON hijo.categoria_padre_id = padre.id
GROUP BY padre.id, padre.nombre
HAVING COUNT(hijo.id) > 0
ORDER BY total_subcategorias DESC;


-- CONSULTA 4: Dos niveles jerárquicos (Nieto -> Hijo -> Raíz)
-- Encadena tres veces la misma tabla para mostrar la ruta completa.
SELECT
    nieto.nombre AS plan_especifico,
    hijo.nombre AS subcategoria,
    abuelo.nombre AS categoria_raiz
FROM categorias_planes nieto
INNER JOIN categorias_planes hijo ON nieto.categoria_padre_id = hijo.id
INNER JOIN categorias_planes abuelo ON hijo.categoria_padre_id = abuelo.id
ORDER BY categoria_raiz, subcategoria, plan_especifico;