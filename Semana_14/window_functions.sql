-- ============================================
-- PROYECTO SEMANAL: Ranking con Window Functions
-- Semana 14 — Window Functions modernas
-- Dominio: Proyecto Telecom (Categorías y Planes Móviles)
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS planes_moviles;
DROP TABLE IF EXISTS categorias_planes;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categorias_planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE planes_moviles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    categoria_id INT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (categoria_id) REFERENCES categorias_planes(id)
);

INSERT INTO categorias_planes (nombre) VALUES ('Postpago'), ('Prepago'), ('Corporativo');

INSERT INTO planes_moviles (nombre, precio, categoria_id) VALUES
    ('Postpago Ultra', 85000.00, 1),
    ('Postpago Premium', 60000.00, 1),
    ('Postpago Pro', 60000.00, 1),
    ('Postpago Básico', 40000.00, 1),
    ('Prepago Joven', 25000.00, 2),
    ('Prepago Joven', 25000.00, 2),
    ('Prepago Minutos', 15000.00, 2),
    ('Prepago Datos', 15000.00, 2),
    ('Corp Avanzado', 120000.00, 3),
    ('Corp Básico', 90000.00, 3);

-- CONSULTA 1: Eliminar duplicados con ROW_NUMBER()
WITH planes_numerados AS (
    SELECT id, nombre, precio, categoria_id,
           ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY id) AS numero_fila
    FROM planes_moviles
)
SELECT id, nombre, precio, categoria_id
FROM planes_numerados
WHERE numero_fila = 1;

-- CONSULTA 2: RANK y DENSE_RANK por categoría
SELECT nombre, precio, categoria_id,
       RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS ranking_normal,
       DENSE_RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS ranking_denso
FROM planes_moviles;

-- CONSULTA 3: Top-2 planes más caros por categoría
WITH ranking_planes AS (
    SELECT nombre, precio, categoria_id,
           DENSE_RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS dense_rnk
    FROM planes_moviles
)
SELECT nombre, precio, categoria_id, dense_rnk
FROM ranking_planes
WHERE dense_rnk <= 2
ORDER BY categoria_id, dense_rnk;