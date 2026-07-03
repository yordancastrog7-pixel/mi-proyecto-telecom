# Semana 15: Análisis Temporal y Vistas en MySQL

* **Consultor de Datos:** Eisin Yordan Castro Guerrero
* **Código de Ficha:** 3228970A
* **Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom

---

## 1. Conceptos Clave

### A. Análisis Temporal (Time-Series Analysis)
El análisis temporal nos permite entender la evolución de un negocio a lo largo del tiempo. 
* **Variación (Delta):** Es la diferencia entre el valor actual y el anterior. Nos indica si un plan móvil está ganando o perdiendo terreno mes a mes.
* **Simulación de Funciones de Ventana:** En entornos donde no disponemos de `LAG()`, utilizamos variables de sesión (`@variable`) para "recordar" el valor de la fila anterior mientras recorremos la tabla, permitiéndonos realizar cálculos comparativos.

### B. Vistas (CREATE VIEW)
Una **Vista** es una "tabla virtual". No almacena datos físicamente, sino que guarda una consulta compleja.
* **Ventaja:** Permite encapsular la lógica de análisis (como los cálculos de mejores/peores meses) para que cualquier persona en el equipo pueda consultar los resultados simplemente haciendo `SELECT * FROM v_period_analysis` sin conocer el código complejo detrás.

---

## 2. Implementación Técnica

### Análisis de Variación
Usamos una lógica de estado para comparar meses consecutivos.
```sql
SELECT periodo_fecha, valor,
       (valor - @prev_valor) AS delta,
       @prev_valor := valor
FROM period_metrics, (SELECT @prev_valor := 0) AS vars;
```

### Encapsulamiento con Vistas
Creamos una vista que precalcula los valores históricos máximos y mínimos por categoría para facilitar reportes gerenciales.
```sql
CREATE OR REPLACE VIEW v_period_analysis AS
SELECT p.periodo_fecha, p.valor,
       (SELECT MAX(valor) FROM period_metrics WHERE categoria_id = p.categoria_id) AS mejor_mes
FROM period_metrics p;
```

### 3. Conclusión
Con este módulo finalizamos el ciclo de consultas avanzadas. Hemos pasado de simples inserciones de datos a realizar análisis predictivos y comparativos, utilizando herramientas de encapsulamiento (Vistas) que son esenciales para cualquier entorno de producción profesional.
