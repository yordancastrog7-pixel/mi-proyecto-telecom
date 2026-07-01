CREATE DATABASE IF NOT EXISTS proyecto_telecom;
USE proyecto_telecom;


CREATE TABLE clientes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_completo VARCHAR(255) NOT NULL,
    cedula VARCHAR(50) UNIQUE NOT NULL,      -- Corregido TEXT -> VARCHAR
    ciudad VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(255) UNIQUE NOT NULL, -- Corregido TEXT -> VARCHAR
    fecha_registro DATE NOT NULL
);

CREATE TABLE planes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_plan VARCHAR(50) CHECK(tipo_plan IN ('Postpago', 'Prepago', 'Recargas')),
    minutos_incluidos INTEGER NOT NULL,
    datos_incluidos DECIMAL(10, 2) NOT NULL,
    precio REAL NOT NULL
);

CREATE TABLE lineas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_celular VARCHAR(50) UNIQUE NOT NULL, -- Corregido TEXT -> VARCHAR
    estado VARCHAR(50) CHECK(estado IN ('Activo', 'Suspendido', 'Cancelado')),
    plan_id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES planes(id),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

CREATE TABLE facturas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    concepto VARCHAR(255) NOT NULL,
    precio_total REAL NOT NULL,
    cliente_id INTEGER NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

