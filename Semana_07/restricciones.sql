-- ============================================
-- PROYECTO SEMANAL: NULL y Constraints
-- Semana 07 — NOT NULL, UNIQUE, CHECK, FK
-- ============================================

-- Activar claves foráneas en MySQL y seleccionar la BD
SET FOREIGN_KEY_CHECKS = 1;
USE proyecto_telecom;

-- Borramos las tablas si ya existen para poder ejecutar el script varias veces sin errores
DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

-- ============================================
-- PARTE 1: ESQUEMA CON CONSTRAINTS
-- ============================================

-- Tabla de "Categorías" (Planes)
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_plan VARCHAR(50) NOT NULL UNIQUE,      -- UNIQUE: No pueden haber dos planes con el mismo nombre
    precio REAL NOT NULL CHECK(precio >= 0)     -- CHECK: El precio no puede ser negativo
);

-- Tabla "Principal" (Líneas)
CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_celular VARCHAR(50) UNIQUE NOT NULL, -- UNIQUE: No pueden haber dos números iguales
    estado VARCHAR(50) DEFAULT 'Activo' CHECK(estado IN ('Activo', 'Suspendido', 'Cancelado')), -- DEFAULT: Si no pones estado, será 'Activo' por defecto
    observaciones VARCHAR(255),                 -- COLUMNA OPCIONAL: Al no tener "NOT NULL", permite valores NULL
    plan_id INTEGER NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES planes(id) ON DELETE RESTRICT -- FK: Relaciona la línea con el plan
);

-- ============================================
-- PARTE 2: DATOS DE PRUEBA
-- ============================================

-- Insertar 3 planes (Categorías)
INSERT INTO planes (tipo_plan, precio) VALUES
    ('Postpago', 50000.00),
    ('Prepago', 20000.00),
    ('Recargas', 10000.00);

-- Insertar 6 líneas (Items)
-- Nota: Dejamos 'observaciones' en NULL para 2 registros (líneas 3 y 6)
INSERT INTO lineas (numero_celular, estado, observaciones, plan_id) VALUES
    ('3001112233', 'Activo', 'Cliente VIP', 1),
    ('3104445566', 'Suspendido', 'Falta de pago', 1),
    ('3207778899', 'Activo', NULL, 2),               -- Columna opcional en NULL
    ('3159990011', 'Cancelado', 'Cambio de operador', 2),
    ('3012223344', 'Activo', 'Línea nueva', 3),
    ('3115556677', 'Activo', NULL, 3);               -- Columna opcional en NULL

    -- ============================================
-- PARTE 3: CONSULTAS CON NULL
-- ============================================

-- 1. Mostrar líneas donde la columna opcional (observaciones) es NULL
SELECT 
    id, 
    numero_celular 
FROM lineas 
WHERE observaciones IS NULL;

-- 2. Mostrar todas las líneas usando COALESCE para reemplazar los valores NULL
-- COALESCE cambia visualmente el "NULL" por el texto 'Sin observaciones'
SELECT 
    numero_celular,
    estado,
    COALESCE(observaciones, 'Sin observaciones') AS detalle_observacion
FROM lineas;