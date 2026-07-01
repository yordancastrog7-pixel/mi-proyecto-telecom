# Semana 06: Funciones de Agregación y Reportes Estadísticos



**Consultor de Datos:** Eisin Yordan Castro Guerrero  

**Código de Ficha:** 3228970A  

**Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)  



---



## 1. Objetivos y Alcance del Módulo



El desarrollo de este componente persigue los siguientes objetivos técnico-prácticos:

* **Dominar el modelado relacional transaccional:** Diseñar estructuras capaces de soportar el histórico de facturación y el estado de líneas móviles de una compañía de telecomunicaciones sin generar duplicidad de información.

* **Optimizar el cálculo masivo de métricas:** Implementar funciones de agregación nativas (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) para la consolidación de reportes de rendimiento financiero y volumetría de usuarios móviles.

* **Garantizar la segmentación eficiente de datos:** Utilizar agrupaciones y condiciones complejas para transformar filas crudas en conocimiento estratégico de distribución comercial y estados de red.



---



## 2. Modelo de Datos y Arquitectura de Relaciones



El diseño se compone de 4 entidades normalizadas para asegurar la consistencia y eliminar redundancias en el almacenamiento de telefonía celular:



* **Clientes (`clientes`):** Entidad maestra que almacena los datos demográficos y los identificadores únicos de los usuarios (`cedula`, `correo_electronico`).

* **Planes (`planes`):** Catálogo de ofertas comerciales exclusivamente móviles (`Postpago`, `Prepago`, `Recargas`) con sus respectivas tarifas base, minutos y datos incluidos.

* **Líneas (`lineas`):** **Tabla Asociativa (Pivote).** Resuelve la relación de muchos a muchos, vinculando de forma directa un número celular con su respectivo cliente y el plan técnico asignado, controlando además su estado actual ('Activo', 'Suspendido', 'Cancelado').

* **Facturas (`facturas`):** Entidad transaccional que registra los cobros mensuales ejecutados, compras de paquetes y recargas, amarrados a cada cliente mediante llaves foráneas.



---



## 3. Análisis Técnico: Fundamentos de Agregación en SQL



Para la construcción de los tableros financieros del proyecto, se aplicó lógica de agregación. Es fundamental comprender el ciclo de vida de una consulta para entender cómo el motor procesa y filtra la información.



### A. Ciclo de Ejecución Lógica del Motor SQL

El motor no procesa los comandos en el orden en que se escriben en el editor. El flujo interno estricto de procesamiento de datos es el siguiente:



1. **FROM / JOIN:** El motor localiza las tablas y las conecta (ej. busca las facturas y valida las relaciones con los clientes).

2. **WHERE:** Aplica un primer filtro fila por fila **antes** de agrupar.

3. **GROUP BY:** Agrupa las filas restantes en conjuntos basados en columnas comunes (ej. agrupa por `tipo_plan` o por `estado`).

4. **HAVING:** Filtra los grupos ya creados evaluando los resultados de funciones matemáticas de agregación.

5. **SELECT:** Proyectas y calculas las columnas finales en la interfaz (es aquí donde se ejecutan los alias `AS`).

6. **ORDER BY:** Ordena el resultado visual definitivo.



### B. Diferencia Arquitectónica: `WHERE` vs. `HAVING`

La correcta separación de estos filtros es crítica para el rendimiento del servidor:



* **`WHERE` (Filtro Pre-Agregación):** Evalúa registros individuales. No tiene acceso a los resultados de funciones como `SUM()`, `COUNT()` o `AVG()`. En este desarrollo, se usa para descartar o incluir filas antes de que el motor gaste memoria agrupando.

* **`HAVING` (Filtro Post-Agregación):** Evalúa exclusivamente los bloques creados por el `GROUP BY`. Es obligatorio usarlo cuando la condición de negocio depende de un cálculo agrupado (ej. evaluar si un estado de línea superó un volumen específico de registros).


---

## 4. Scripts Analíticos Consolidados (Pruebas de Producción)



A continuación se detalla el bloque de código consolidado y ejecutado con éxito en el entorno de desarrollo, adaptadas al volumen real de nuestra base de datos (50 registros transaccionales):



```sql

-- ====================================================================

-- CONSULTA 1: RENDIMIENTO COMERCIAL POR TIPO DE PLAN

-- Propósito: Agrupar el catálogo de planes comerciales para analizar qué

-- segmentos ofrecen mayor variedad y evaluar sus costos promedio de oferta.

-- ====================================================================

SELECT

    tipo_plan,

    COUNT(*) AS cantidad_de_planes,

    AVG(precio) AS precio_promedio

FROM planes

GROUP BY tipo_plan

ORDER BY cantidad_de_planes DESC;



-- ====================================================================

-- CONSULTA 2: TOTALES GLOBALES Y EXTREMOS FINANCIEROS

-- Propósito: Consolidar el volumen total de transacciones físicas, el

-- recaudo bruto total, el ticket promedio y los límites económicos del negocio.

-- ====================================================================

SELECT

    COUNT(*) AS total_facturas,

    SUM(precio_total) AS ingresos_totales,

    AVG(precio_total) AS promedio_por_factura,

    MIN(precio_total) AS factura_minima,

    MAX(precio_total) AS factura_maxima

FROM facturas;


-- ====================================================================

-- CONSULTA 3: FILTRO AVANZADO DE ESTADOS CRÍTICOS DE LÍNEAS (HAVING)

-- Propósito: Agrupar las líneas según su estado de red, aislando únicamente

-- aquellos grupos operativos que representen una masa crítica superior a 5 líneas.

-- ====================================================================

SELECT

    estado,

    COUNT(*) AS total_lineas

FROM lineas

GROUP BY estado

HAVING COUNT(*) > 5

ORDER BY total_lineas DESC;

"/> 

