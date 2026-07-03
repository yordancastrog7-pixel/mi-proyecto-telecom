# Semana 13: Jerarquías con CTEs Recursivas (WITH RECURSIVE)

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)

---

## 1. Objetivos y Alcance del Módulo

El propósito de esta semana es aprender a manejar datos que tienen forma de "árbol genealógico" (donde un dato es padre de otro, y ese a su vez es padre de otro). Para esto usamos **Consultas Recursivas**:

* **WITH RECURSIVE:** Es una herramienta avanzada pero lógica. Funciona como un bucle. Primero busca la "raíz" del árbol (el elemento principal) y luego se repite a sí misma buscando a los hijos, luego a los nietos, y así sucesivamente hasta que ya no encuentra más ramas.
* **Caso Base y Caso Recursivo:** Toda consulta recursiva tiene dos partes. El *Caso Base* es el punto de partida (ej. el Catálogo Principal). El *Caso Recursivo* es la regla para encontrar a los descendientes.
* **Navegación de Árboles:** Aprender a calcular en qué "nivel de profundidad" está un dato y construir la "ruta" visual de cómo llegar a él (ej. Catálogo > Postpago > Plan Ultra).

---

## 2. Adaptación del Modelo de Datos

Para practicar esto, creamos una estructura donde las categorías se relacionan consigo mismas:

* **Tabla Auto-Referencial (`categorias_productos`):** Es una tabla única. Su magia radica en la columna `categoria_padre_id`. Si un registro tiene un número en esa columna, significa que pertenece a otra categoría dentro de esta misma tabla. Si tiene `NULL`, significa que es el nivel más alto (la raíz).

---

## 3. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, los códigos utilizados esta semana, adaptados a la sintaxis de MySQL y explicados de forma sencilla.

### A. Inicialización y Creación de la Estructura

Creamos la tabla haciendo que su llave foránea apunte a su propia llave primaria.

```sql
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;

DROP TABLE IF EXISTS categorias_productos;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categorias_productos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    categoria_padre_id INT,
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias_productos(id)
); 

```

### B. Inserción de Datos (Construyendo el árbol)
Agregamos datos en 3 niveles simulando un catálogo de ventas real.

```sql
-- Nivel 1: Nodo raíz (No tiene padre, es el inicio de todo)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(1, 'Catálogo Móvil', NULL);

-- Nivel 2: Nodos hijos (Pertenecen al ID 1)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(2, 'Planes Postpago', 1),
(3, 'Planes Prepago', 1);

-- Nivel 3: Nodos nietos (Pertenecen a los ID 2 o 3)
INSERT INTO categorias_productos (id, nombre, categoria_padre_id) VALUES 
(4, 'Postpago Ultra 100GB', 2),
(5, 'Postpago Básico 30GB', 2),
(6, 'Prepago Joven 15GB', 3),
(7, 'Prepago Minutos', 3);

```

### C. Recorrer el árbol completo (Generar la Ruta)
Esta consulta es el corazón de la semana. Primero toma la raíz (WHERE categoria_padre_id IS NULL). Luego, usa UNION ALL para sumarle los hijos recursivamente. Usamos CONCAT para dibujar la ruta y profundidad + 1 para saber en qué nivel estamos.

```SQL

WITH RECURSIVE arbol AS (
    -- Caso base — Nodo raíz (Nivel 1)
    SELECT id, nombre, categoria_padre_id,
        1 AS profundidad,
        CAST(nombre AS CHAR(255)) AS ruta
    FROM categorias_productos
    WHERE categoria_padre_id IS NULL

    UNION ALL

    -- Caso recursivo — Buscar hijos
    SELECT c.id, c.nombre, c.categoria_padre_id,
        a.profundidad + 1,
        CONCAT(a.ruta, ' > ', c.nombre)
    FROM categorias_productos c
    INNER JOIN arbol a ON c.categoria_padre_id = a.id
)
SELECT profundidad,
    CONCAT(REPEAT('  ', profundidad - 1), nombre) AS nombre_indentado,
    ruta
FROM arbol
ORDER BY ruta;
```
###  D. Filtrar un nivel específico
Usamos la misma lógica del punto anterior, pero al final le decimos al sistema que solo nos muestre los resultados que cayeron en el nivel de profundidad 3.
```SQL
WITH RECURSIVE arbol AS (
    SELECT id, nombre, categoria_padre_id, 1 AS profundidad, CAST(nombre AS CHAR(255)) AS ruta
    FROM categorias_productos
    WHERE categoria_padre_id IS NULL
    UNION ALL
    SELECT c.id, c.nombre, c.categoria_padre_id, a.profundidad + 1, CONCAT(a.ruta, ' > ', c.nombre)
    FROM categorias_productos c
    INNER JOIN arbol a ON c.categoria_padre_id = a.id
)
SELECT nombre, profundidad, ruta
FROM arbol
WHERE profundidad = 3
ORDER BY ruta;
```

### E. Búsqueda de Hojas (Nodos sin hijos)
Para encontrar los productos finales (los que están en la punta de las ramas y no tienen subdivisiones), buscamos aquellos registros a los cuales NADIE los llama "padre". Para esto es ideal el NOT EXISTS.

```SQL
SELECT c.id, c.nombre AS plan_final_sin_hijos
FROM categorias_productos c
WHERE NOT EXISTS (
    SELECT 1
    )FROM categorias_productos sub
    WHERE sub.categoria_padre_id = c.id
)
ORDER BY c.nombre;
```