
# Semana 09: Relaciones y Cruces de Datos (JOINs)

**Consultor de Datos:** Eisin Yordan Castro Guerrero  
**Código de Ficha:** 3228970A  
**Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)  

---

## 1. Objetivos y Alcance del Módulo

El desarrollo de este laboratorio técnico tiene como propósito dominar la consulta de bases de datos relacionales mediante la combinación de tablas:
* **Integración de Entidades (`INNER JOIN`):** Extraer información combinada cruzando tablas dependientes para formar reportes unificados, filtrando únicamente los datos que tienen correspondencia exacta.
* **Análisis de Discrepancias (`LEFT JOIN`):** Identificar asimetrías en el negocio, como productos que no han sido vendidos o, en este caso, líneas móviles que no han generado facturación (registros huérfanos).
* **Agregación Multitabla:** Combinar el cruce de datos con funciones estadísticas (`COUNT`) para analizar el volumen transaccional por ítem.

---

## 2. Adaptación del Modelo de Datos

Para cumplir con el requerimiento de una estructura encadenada de tres niveles (Referencia -> Principal -> Hija), se adaptó el dominio de la siguiente manera:
1. **Referencia (`planes`):** Catálogo de categorías.
2. **Principal (`lineas`):** Ítems operativos vinculados a un plan.
3. **Hija (`facturas`):** Transacciones financieras vinculadas directamente a una línea.

---

## 3. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, se detalla el código ejecutado en el entorno de desarrollo (MySQL), separando la construcción estructural de las consultas lógicas.

### A. Inicialización y Limpieza del Entorno
Desactivamos temporalmente las llaves foráneas para poder borrar las tablas sin errores de dependencia, y luego las reactivamos.

```sql
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS facturas;
DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

SET FOREIGN_KEY_CHECKS = 1;

```
### B. Creación de la Estructura Relacional
Se crean las tres tablas encadenadas con sus respectivas llaves primarias (PK) y foráneas (FK).
```sql
-- Tabla de referencia (Categorías de Planes)
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_plan VARCHAR(50) NOT NULL UNIQUE
);
-- Tabla principal (Líneas Móviles)
CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_celular VARCHAR(50) NOT NULL UNIQUE,
    plan_id INT,
    FOREIGN KEY (plan_id) REFERENCES planes(id)
);
-- Tabla hija (Transacciones / Facturas)
CREATE TABLE facturas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    linea_id INT,
    FOREIGN KEY (linea_id) REFERENCES lineas(id)
);
```

### C. Inserción de Datos de Prueba (Escenario con Huérfanos)
Se inyectan datos transaccionales de mayo de 2026. Se incluye intencionalmente una línea (la terminada en 8899) que no tendrá facturas asociadas para simular el registro "huérfano" requerido en la auditoría.
```sql
-- Inserción de Planes
INSERT INTO planes (nombre_plan) VALUES 
    ('Postpago Plus'), 
    ('Prepago Básico'), 
    ('Datos Ilimitados');

-- Inserción de Líneas (La línea 3 será el registro huérfano)
INSERT INTO lineas (numero_celular, plan_id) VALUES
    ('3001112233', 1),
    ('3104445566', 2),
    ('3207778899', 3), -- Sin facturas
    ('3159990011', 1);

-- Inserción de Facturas
INSERT INTO facturas (fecha, monto, linea_id) VALUES
    ('2026-05-01', 50000.00, 1),
    ('2026-05-15', 50000.00, 1),
    ('2026-05-10', 20000.00, 2),
    ('2026-05-20', 50000.00, 4);
   
   ```
   
### D. Consultas de Relación (INNER JOIN)
Cruces estrictos donde ambas tablas deben coincidir. La consulta 2 demuestra cómo encadenar múltiples tablas en un solo reporte.

```sql
-- CONSULTA 1: INNER JOIN principal
-- Une líneas y facturas (Solo líneas que tienen facturas generadas)
SELECT
    l.numero_celular AS linea_operativa,
    f.fecha AS fecha_facturacion,
    f.monto
FROM lineas l
INNER JOIN facturas f ON f.linea_id = l.id;

-- CONSULTA 2: JOIN con tres tablas
-- Encadena catálogo de planes + líneas móviles + facturas generadas
SELECT
    p.nombre_plan AS plan_comercial,
    l.numero_celular AS linea,
    f.fecha AS fecha_emision,
    f.monto AS valor_cobrado
FROM lineas l
INNER JOIN planes p ON l.plan_id = p.id
INNER JOIN facturas f ON f.linea_id = l.id;

```

### E. Consultas de Inclusión y Detección de Huérfanos (LEFT JOIN)
El LEFT JOIN trae todas las líneas, sin importar si han facturado o no. Usando WHERE f.id IS NULL, logramos aislar el registro huérfano.

```sql
-- CONSULTA 3: LEFT JOIN — Todos los registros
-- Obtiene todas las líneas, rellenando con NULL si no hay facturas
SELECT
    l.numero_celular AS inventario_lineas,
    f.fecha AS ultima_actividad,
    f.monto
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id;
-- CONSULTA 4: Detectar huérfanos
-- Aísla la línea específica que no tiene transacciones asociadas
SELECT
    l.numero_celular AS linea_sin_facturas
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id
WHERE f.id IS NULL;

```

### F. Reporte Estadístico Combinado
Integración de LEFT JOIN con funciones de agregación para obtener un conteo total, respetando los ceros en líneas sin transacciones.

```sql
-- CONSULTA 5: Reporte agregado con LEFT JOIN + COUNT
-- Calcula el volumen de facturas por línea (incluyendo cantidad 0)
SELECT
    l.numero_celular AS linea,
    COUNT(f.id) AS total_facturas_emitidas
FROM lineas l
LEFT JOIN facturas f ON f.linea_id = l.id
GROUP BY l.numero_celular
ORDER BY total_facturas_emitidas DESC; 

```