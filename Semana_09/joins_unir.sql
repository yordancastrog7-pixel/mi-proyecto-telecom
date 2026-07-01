-- ============================================
-- PROYECTO SEMANAL: JOINs aplicados a tu dominio
-- Semana 09 — INNER JOIN y LEFT JOIN
-- ============================================

-- Desactivamos restricciones temporalmente para limpiar el entorno sin errores
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS facturas;
DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

-- Reactivamos las restricciones de llaves foráneas
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- PARTE 1: CREACIÓN DE ESTRUCTURA (3 NIVELES)
-- ============================================

-- 1. Tabla de referencia (Categorías de Planes)
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Tabla principal (Líneas Móviles)
CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_celular VARCHAR(50) NOT NULL UNIQUE,
    plan_id INT,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);

-- 3. Tabla hija (Transacciones / Facturas)
CREATE TABLE facturas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    linea_id INT,
    FOREIGN KEY (linea_id) REFERENCES lineas(id)
);

-- ============================================
-- PARTE 2: INSERCIÓN DE DATOS DE PRUEBA
-- ============================================

INSERT INTO planes (nombre_plan) VALUES 
    ('Postpago Plus'), 
    ('Prepago Básico'), 
    ('Datos Ilimitados');

-- Nota: La línea terminada en '8899' será nuestro registro "huérfano" (sin facturas)
INSERT INTO lineas (numero_celular, plan_id) VALUES
    ('3001112233', 1),
    ('3104445566', 2),
    ('3207778899', 3), 
    ('3159990011', 1);

INSERT INTO facturas (fecha, monto, linea_id) VALUES
    ('2026-05-01', 50000.00, 1),
    ('2026-05-15', 50000.00, 1),
    ('2026-05-10', 20000.00, 2),
    ('2026-05-20', 50000.00, 4);

-- ============================================
-- PARTE 3: CONSULTAS JOIN (PRUEBAS LÓGICAS)
-- ============================================

-- CONSULTA 1: INNER JOIN principal
-- Muestra solo las líneas que tienen facturas, ignorando a los huérfanos.
SELECT
    l.numero_celular AS linea_operativa,
    f.fecha AS fecha_facturacion,
    f.monto
FROM lineas l
INNER JOIN facturas f ON f.linea_id = l.id;


-- CONSULTA 2: JOIN con tres tablas
-- Encadena toda la ruta: Plan -> Línea -> Factura
SELECT
    p.nombre_plan AS plan_comercial,
    l.numero_celular AS linea,
    f.fecha AS fecha_emision,
    f.monto AS valor_cobrado
FROM lineas l
INNER JOIN planes p ON l.plan_id = p.id
INNER JOIN facturas f ON f.linea_id = l.id;


-- CONSULTA 3: LEFT JOIN — Todos los registros
-- Muestra TODAS las líneas. Si no tienen factura, mostrará valores NULL en fecha y monto.
SELECT
    l.numero_celular AS inventario_lineas,
    f.fecha AS ultima_actividad,
    f.monto
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id;


-- CONSULTA 4: Detectar huérfanos (registros sin actividad)
-- Aísla exclusivamente la línea '3207778899' usando la condición IS NULL
SELECT
    l.numero_celular AS linea_sin_facturas
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id
WHERE f.id IS NULL;


-- CONSULTA 5: Reporte agregado con LEFT JOIN + COUNT
-- Muestra el total de facturas por línea (la huérfana debe salir con 0)
SELECT
    l.numero_celular AS linea,
    COUNT(f.id) AS total_facturas_emitidas
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id
GROUP BY l.numero_celular
ORDER BY total_facturas_emitidas DESC;