# Semana 07: Restricciones de Integridad (Constraints) y Gestión de Valores Nulos (NULL)

**Consultor de Datos:** Eisin Yordan Castro Guerrero  
**Código de Ficha:** 3228970A  
**Dominio del Negocio:** Sistema de Facturación Analítica - Proyecto Telecom (Solo Conectividad Móvil)  

---

## 1. Objetivos y Alcance del Módulo

El desarrollo de este laboratorio técnico persigue los siguientes objetivos prácticos de arquitectura de software:
* **Garantizar la Integridad de Entidades:** Implementar restricciones a nivel de motor de base de datos (`NOT NULL`, `UNIQUE`) para asegurar que los identificadores de red y catálogos comerciales no sufran de duplicidad ni datos huérfanos.
* **Aplicar Reglas de Negocio en el Almacenamiento:** Utilizar restricciones de validación (`CHECK`) y asignaciones automatizadas (`DEFAULT`) para blindar las tablas contra estados operativos inválidos o valores financieros negativos.
* **Dominar el Tratamiento de Datos Ausentes:** Gestionar de forma profesional la ausencia de información en columnas opcionales utilizando operadores lógicos específicos (`IS NULL`) y funciones de transformación en la capa de persistencia (`COALESCE`).

---

## 2. Modelo de Datos y Arquitectura de Restricciones

Para este componente práctico, se aisló y robusteció un segmento crítico del dominio de telecomunicaciones móviles, estructurado en una relación de categorías y registros principales:

* **Catálogo de Planes (`planes`):** Actúa como la tabla de categorías comerciales. Implementa una restricción `UNIQUE` en el tipo de plan para evitar ofertas comerciales duplicadas en el sistema, y un control `CHECK` que impide la inserción de tarifas inferiores a cero.
* **Control de Líneas Móviles (`lineas`):** Entidad transaccional principal encargada de la simulación operativa. Cuenta con una llave foránea (`FOREIGN KEY`) vinculada al catálogo de planes con integridad referencial estricta. Integra una columna opcional (`observaciones`) diseñada estructuralmente para admitir la ausencia de valor (`NULL`) sin romper la consistencia del registro.

---

## 3. Análisis Técnico: Integridad y Lógica Transaccional en SQL

El diseño seguro de una base de datos requiere transferir las reglas operativas del negocio directamente a las restricciones del motor SQL. En esta sección se detallan los fundamentos aplicados.

### A. Tipos de Restricciones y su Rol en el Servidor
1. **`NOT NULL`:** Obliga a que la columna contenga datos válidos. Evita que campos críticos de facturación o identificación queden en el limbo operativo.
2. **`UNIQUE`:** Instala un índice único que prohíbe valores repetidos (ej. un mismo número celular o cédula no puede existir dos veces en la tabla).
3. **`CHECK`:** Actúa como un filtro de validación en tiempo de ejecución. Si un dato no cumple la condición booleana (ej. que el estado pertenezca estrictamente a la lista `'Activo'`, `'Suspendido'`, `'Cancelado'`), el motor aborta la transacción inmediatamente.
4. **`DEFAULT`:** Optimiza la experiencia de inserción asignando un estado inicial automático (ej. `'Activo'`) si la aplicación cliente no lo define explícitamente.

### B. El Concepto de `NULL` y la Función `COALESCE`
En bases de datos relacionales, `NULL` no representa un cero numérico, ni un espacio en blanco, ni una cadena de texto vacía; representa la **ausencia total de valor** o un dato desconocido. 

Para evitar problemas de visualización en las interfaces de usuario o reportes finales, se utilizó la función nativa **`COALESCE`**:
* **Lógica Interna:** Recibe una lista de argumentos y devuelve el primer valor que no sea `NULL`. 
* **Aplicación:** Al evaluar la columna opcional `observaciones`, si el motor encuentra un registro nulo, lo intercepta dinámicamente y lo reemplaza por una cadena genérica estructurada (`'Sin observaciones'`), manteniendo el reporte limpio, estandarizado y profesional.

---

## 4. Scripts Analíticos Consolidados (Pruebas de Producción)

A continuación, se detalla el código ejecutado en el entorno de desarrollo (MySQL). Para mayor claridad, se ha separado la lógica de negocio del código limpio.

### A. Inicialización y Limpieza del Entorno
Antes de crear las tablas, habilitamos las restricciones de llaves foráneas y nos aseguramos de borrar tablas previas para evitar errores de duplicidad al correr el script varias veces.

```sql
SET FOREIGN_KEY_CHECKS = 1;
USE proyecto_telecom;

DROP TABLE IF EXISTS lineas;
DROP TABLE IF EXISTS planes;

```

### B. Creación de la Tabla 'planes' (Categorías)
Definimos el catálogo comercial. Utilizamos UNIQUE para asegurar que no se repitan los nombres de los planes y CHECK para garantizar que el precio nunca sea negativo.

```sql
CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_plan VARCHAR(50) NOT NULL UNIQUE,
    precio REAL NOT NULL CHECK(precio >= 0)
);
```

### C. Creación de la Tabla 'lineas' (Principal)
Tabla transaccional que utiliza DEFAULT para asignar automáticamente el estado 'Activo' si no se especifica. La columna observaciones se deja sin la restricción NOT NULL, permitiendo intencionalmente valores vacíos para este laboratorio.
```sql
CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_celular VARCHAR(50) UNIQUE NOT NULL,
    estado VARCHAR(50) DEFAULT 'Activo' CHECK(estado IN ('Activo', 'Suspendido', 'Cancelado')),
    observaciones VARCHAR(255),
    plan_id INTEGER NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES planes(id) ON DELETE RESTRICT
);
```
### D. Inserción de Datos de Prueba (Simulación de Nulos)
Inyectamos el catálogo base y 6 líneas móviles. Se inserta intencionalmente el valor NULL en dos registros para probar posteriormente las funciones de limpieza de datos.
```sql
INSERT INTO planes (tipo_plan, precio) VALUES
    ('Postpago', 50000.00),
    ('Prepago', 20000.00),
    ('Recargas', 10000.00);

INSERT INTO lineas (numero_celular, estado, observaciones, plan_id) VALUES
    ('3001112233', 'Activo', 'Cliente VIP', 1),
    ('3104445566', 'Suspendido', 'Falta de pago', 1),
    ('3207778899', 'Activo', NULL, 2),
    ('3159990011', 'Cancelado', 'Cambio de operador', 2),
    ('3012223344', 'Activo', 'Línea nueva', 3),
    ('3115556677', 'Activo', NULL, 3);
```
  ### E. Consultas de Auditoría (Tratamiento de NULL)
La primera consulta aísla estrictamente los registros vacíos utilizando IS NULL. La segunda consulta genera un reporte unificado utilizando COALESCE para reemplazar visualmente los valores nulos por el texto 'Sin observaciones'.
```sql
-- 1. Aislamiento de excepciones
SELECT 
    id, 
    numero_celular 
FROM lineas 
WHERE observaciones IS NULL;

-- 2. Reporte unificado con formateo dinámico
SELECT 
    numero_celular,
    estado,
    COALESCE(observaciones, 'Sin observaciones') AS detalle_observacion
FROM lineas;
```