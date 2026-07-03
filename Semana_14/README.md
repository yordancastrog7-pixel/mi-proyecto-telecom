# Semana 14: Window Functions (Funciones de Ventana)

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Planes Móviles)

---

## 1. Objetivos y Alcance del Módulo

El objetivo de esta semana es aprender a realizar cálculos analíticos avanzados sobre conjuntos de datos manteniendo el detalle de las filas individuales.

* **Window Functions:** Permiten hacer cálculos sobre un "grupo" de filas sin necesidad de agruparlas (sin `GROUP BY`), lo que nos permite mantener la información detallada.
* **ROW_NUMBER():** Asigna un número secuencial único a cada fila. Es la herramienta estándar para detectar y filtrar registros duplicados.
* **RANK() y DENSE_RANK():** Permiten crear clasificaciones (rankings) competitivas. 
    * `RANK()` crea saltos en la numeración ante empates.
    * `DENSE_RANK()` numera de forma continua sin saltos.

---

## 2. Aplicación Práctica en el Proyecto Telecom

Usamos estas funciones para limpiar nuestro catálogo de planes móviles y para generar clasificaciones de precios de forma profesional.

---

## 3. Scripts Analíticos (Pruebas de Producción)

### A. Estructura y Datos
Creamos la estructura de categorías y planes, insertando datos con duplicados y empates intencionales para probar el comportamiento de las funciones.

```sql
CREATE TABLE categorias_planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE planes_moviles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    categoria_id INT,
    FOREIGN KEY (categoria_id) REFERENCES categorias_planes(id)
);
```

### B. Eliminación de Duplicados
Usamos ROW_NUMBER() para identificar duplicados por nombre y filtrar solo el primer registro.

```sql
WITH planes_numerados AS (
    SELECT id, nombre, precio, categoria_id,
           ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY id) AS numero_fila
    FROM planes_moviles
)
SELECT id, nombre, precio, categoria_id
FROM planes_numerados
WHERE numero_fila = 1;
```

### C. Rankings de Precios
Utilizamos RANK() y DENSE_RANK() para clasificar los planes de mayor a menor precio dentro de cada categoría.
```sql
SELECT nombre, precio, categoria_id,
       RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS ranking_normal,
       DENSE_RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS ranking_denso
FROM planes_moviles;

D. Top-N por Categoría
Obtenemos los 2 planes con mayor precio usando un ranking denso filtrado.

WITH ranking_planes AS (
    SELECT nombre, precio, categoria_id,
           DENSE_RANK() OVER (PARTITION BY categoria_id ORDER BY precio DESC) AS dense_rnk
    FROM planes_moviles
)
SELECT nombre, precio, categoria_id, dense_rnk
FROM ranking_planes
WHERE dense_rnk <= 2
ORDER BY category_id, dense_rnk;
```