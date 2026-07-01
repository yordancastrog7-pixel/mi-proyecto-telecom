# Semana 10: Jerarquías y Referencias Cruzadas (SELF JOIN)

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)

---

## 1. Objetivos y Alcance del Módulo

El propósito de este laboratorio técnico es dominar la gestión de estructuras jerárquicas dentro de una misma entidad, fortaleciendo la capacidad analítica sobre modelos auto-referenciales:

* **Modelado Auto-Referencial:** Diseñar tablas con llaves foráneas apuntando a su propia llave primaria para representar árboles de datos (categorías, subcategorías, organigramas).
* **Navegación de Árboles (SELF JOIN):** Implementar cruces de una tabla consigo misma utilizando Alias (*hijo*, *padre*, *abuelo*) para simular múltiples tablas en memoria y trazar la ruta lógica de los datos.
* **Control de Nodos Raíz:** Combinar el uso de `LEFT JOIN` y la función `COALESCE` para manejar elegantemente el registro principal de la jerarquía (aquel que no tiene un nivel superior).

---

## 2. Adaptación del Modelo de Datos

Para cumplir con el requerimiento de una estructura jerárquica (**Padre → Hijo**), se diseñó la siguiente entidad en el dominio de telecomunicaciones:

* **Árbol de Categorías Comerciales (`categorias_planes`):** Una tabla única que almacena la raíz operativa (*"Conectividad Móvil"*), las familias de productos (*"Postpago"*, *"Prepago"*) y los planes específicos de venta final (*"Postpago Plus 50GB"*), enlazados a través de la columna `categoria_padre_id`.

---

## 3. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, se detalla el código ejecutado en el entorno de desarrollo (**MySQL**), separando la construcción estructural de las consultas lógicas.

### A. Inicialización y Creación de la Estructura Jerárquica

Se crea la tabla auto-referencial. Note cómo la llave foránea `categoria_padre_id` apunta a la columna `id` de la misma tabla.

```sql
SET FOREIGN_KEY_CHECKS = 0;
USE proyecto_telecom;
DROP TABLE IF EXISTS categorias_planes;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categorias_planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    categoria_padre_id INT,
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias_planes(id)
);
```

### B. Inserción de Datos (Construcción del Árbol)

Se inyectan 6 registros estructurados en 3 niveles de profundidad: 1 Raíz, 3 Hijos y 2 Nietos.

```sql
-- 1. Registro RAÍZ (Nivel 0 - No tiene padre, su parent_id es NULL)
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) 
VALUES (1, 'Conectividad Móvil', NULL);

-- 2. Registros HIJOS (Nivel 1 - Su padre es la raíz [ID 1])
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) 
VALUES 
(2, 'Líneas Postpago', 1),
(3, 'Líneas Prepago', 1),
(4, 'Paquetes de Datos', 1);

-- 3. Registros NIETOS (Nivel 2 - Sus padres son los registros del Nivel 1)
INSERT INTO categorias_planes (id, nombre, categoria_padre_id) 
VALUES 
(5, 'Postpago Plus 50GB', 2),
(6, 'Prepago Básico 5GB', 3);
```

### C. Navegación Básica de 2 Niveles (INNER JOIN y LEFT JOIN)

La consulta 1 excluye la raíz (ya que no tiene padre). La consulta 2 incluye toda la jerarquía, utilizando `COALESCE` para etiquetar dinámicamente el nivel cero.

```sql
-- CONSULTA 1: SELF JOIN básico (Excluye la raíz)
SELECT 
    hijo.nombre AS subcategoria, 
    padre.nombre AS categoria_padre 
FROM categorias_planes hijo 
INNER JOIN categorias_planes padre ON hijo.categoria_padre_id = padre.id;

-- CONSULTA 2: Incluir la raíz con LEFT JOIN y etiquetado
SELECT 
    hijo.nombre AS categoria, 
    COALESCE(padre.nombre, '--- Categoría Principal (Raíz) ---') AS pertenece_a 
FROM categorias_planes hijo 
LEFT JOIN categorias_planes padre ON hijo.categoria_padre_id = padre.id 
ORDER BY pertenece_a, categoria;
```

### D. Agregación y Profundidad Avanzada

La consulta 3 cuenta cuántos ramales descienden de cada categoría. La consulta 4 encadena la misma tabla tres veces para visualizar el linaje completo de los planes comerciales.

```sql
-- CONSULTA 3: Contar hijos directos por padre
SELECT 
    padre.nombre AS categoria_padre, 
    COUNT(hijo.id) AS total_subcategorias 
FROM categorias_planes padre 
LEFT JOIN categorias_planes hijo ON hijo.categoria_padre_id = padre.id 
GROUP BY padre.id, padre.nombre 
HAVING COUNT(hijo.id) > 0 
ORDER BY total_subcategorias DESC;

-- CONSULTA 4: Tres niveles jerárquicos (Nieto -> Hijo -> Raíz)
SELECT 
    nieto.nombre AS plan_especifico, 
    hijo.nombre AS subcategoria, 
    abuelo.nombre AS categoria_raiz 
FROM categorias_planes nieto 
INNER JOIN categorias_planes hijo ON nieto.categoria_padre_id = hijo.id 
INNER JOIN categorias_planes abuelo ON hijo.categoria_padre_id = abuelo.id 
ORDER BY categoria_raiz, subcategoria, plan_especifico;
```
