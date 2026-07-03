-- ============================================
-- PROYECTO SEMANAL: Análisis temporal
-- Semana 15 — LEAD, LAG y VISTAS
-- Dominio: Proyecto Telecom (Facturación mensual por categoría)
-- Nota: Adaptado a sintaxis MySQL 5.7+
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP VIEW IF EXISTS v_period_analysis;
DROP TABLE IF EXISTS period_metrics;
DROP TABLE IF EXISTS categorias_analisis;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categorias_analisis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE period_metrics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    periodo_fecha DATE NOT NULL,
    categoria_id INT,
    valor DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (categoria_id) REFERENCES categorias_analisis(id)
);

INSERT INTO categorias_analisis (nombre) VALUES ('Postpago'), ('Prepago');

INSERT INTO period_metrics (periodo_fecha, categoria_id, valor) VALUES
    ('2024-01-01', 1, 1000.00),
    ('2024-02-01', 1, 1200.00),
    ('2024-03-01', 1, 900.00),
    ('2024-04-01', 1, 1500.00),
    ('2024-01-01', 2, 800.00),
    ('2024-02-01', 2, 850.00),
    ('2024-03-01', 2, 780.00),
    ('2024-04-01', 2, 920.00);

    -- ============================================
-- CONSULTA 1: Variación mensual (Simulando LAG)
-- Objetivo: Comparar el valor actual vs el del mes anterior
-- ============================================

SELECT 
    periodo_fecha, 
    categoria_id, 
    valor AS valor_actual,
    @prev_valor AS valor_anterior,
    (valor - @prev_valor) AS delta,
    @prev_valor := valor -- Actualizamos la variable para la siguiente fila
FROM period_metrics, (SELECT @prev_valor := 0) AS vars
ORDER BY categoria_id, periodo_fecha;


-- ============================================
-- CONSULTA 2 y 3: Análisis de mejores/peores meses y VISTA
-- Objetivo: Crear una vista que encapsule el análisis histórico
-- ============================================

CREATE OR REPLACE VIEW v_period_analysis AS
SELECT 
    p.periodo_fecha, 
    p.categoria_id, 
    p.valor,
    -- Obtenemos el mejor valor histórico (máximo por categoría)
    (SELECT MAX(valor) FROM period_metrics WHERE categoria_id = p.categoria_id) AS mejor_mes,
    -- Obtenemos el peor valor histórico (mínimo por categoría)
    (SELECT MIN(valor) FROM period_metrics WHERE categoria_id = p.categoria_id) AS peor_mes
FROM period_metrics p;

-- Consultamos la vista filtrando por la categoría 1
SELECT * FROM v_period_analysis WHERE categoria_id = 1;