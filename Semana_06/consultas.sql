
-- PROYECTO SEMANAL: Funciones de Agregación
-- Semana 06 — COUNT, SUM, AVG, GROUP BY, HAVING


-- NOTA: Consultas adaptadas al dominio 'proyecto_telecom'


-- REPORTE 1: Totales globales
-- ============================================
-- TODO: Cuenta todos los registros y calcula suma/promedio
--       de la columna numérica más relevante de tu dominio.
-- Aplicación: Conocer el volumen total de ingresos y el ticket promedio de las facturas.

SELECT 
    COUNT(*) AS total_facturas,
    SUM(precio_total) AS ingresos_totales,
    AVG(precio_total) AS promedio_por_factura
FROM facturas;


-- ============================================
-- REPORTE 2: Extremos
-- ============================================
-- TODO: Obtén el valor mínimo y máximo de la columna numérica.
-- Aplicación: Identificar el valor de la factura más económica y la más costosa registrada.

SELECT 
    MIN(precio_total) AS factura_minima,
    MAX(precio_total) AS factura_maxima
FROM facturas;

-- ============================================
-- REPORTE 3: Subtotales por categoría (GROUP BY)
-- ============================================
-- TODO: Agrupa por la columna de categoría/tipo principal de tu dominio
--       y calcula COUNT + AVG o SUM para cada grupo.
-- Aplicación: Analizar el catálogo de planes agrupándolos por tipo (Postpago, Prepago, Recargas).

SELECT 
    tipo_plan,
    COUNT(*) AS cantidad_de_planes,
    AVG(precio) AS precio_promedio
FROM planes
GROUP BY tipo_plan
ORDER BY cantidad_de_planes DESC;

-- ============================================
-- REPORTE 4: Filtro de grupos (HAVING)
-- ============================================
-- TODO: Muestra solo los grupos que superen un umbral de negocio.
-- Aplicación: Ver los estados de las líneas (Activo, Suspendido, Cancelado), 
-- filtrando solo aquellos estados que tengan más de 5 líneas asociadas.

SELECT 
    estado,
    COUNT(*) AS total_lineas
FROM lineas
GROUP BY estado
HAVING COUNT(*) > 5;