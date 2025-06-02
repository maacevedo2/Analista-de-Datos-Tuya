--- Creacion de tablas
CREATE TABLE cliente (
    cedula SERIAL PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL,
    telefono VARCHAR(20)
);

CREATE TABLE orden (
    id_orden SERIAL PRIMARY KEY,
    nro_orden VARCHAR(10),
    cedula INT NOT NULL,
    fecha_orden TIMESTAMP NOT NULL,
    total_pedido DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (cedula) REFERENCES cliente(cedula)
);

CREATE TABLE proveedor (
    id_proveedor SERIAL PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL,
    telefono VARCHAR(20)
);

CREATE TABLE producto (
    id_producto SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(50) NOT NULL,
    id_proveedor INT NOT NULL,
    precio_unitario DECIMAL(12,2),
    activo_sn BOOLEAN NOT NULL,
    FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

CREATE TABLE detalle_orden (
    id_orden INT,
    id_producto INT,
    precio_unitario DECIMAL(12,2) NOT NULL,
    cantidad INT NOT NULL,
    PRIMARY KEY (id_orden, id_producto),
    FOREIGN KEY (id_orden) REFERENCES orden(id_orden),
    FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);


--- Datos de prueba
INSERT INTO cliente (nombre, telefono) VALUES 
('Maria Acevedo', '1111111111'),
('Alejandra Acevedo', NULL),
('Maria Echavarria', '2222222222'),
('Alejandra Echavarria', '3333333333');

INSERT INTO orden (nro_orden, cedula, fecha_orden, total_pedido) VALUES 
('ORDEN_001', 1, '2020-12-10', 5550.00),
('ORDEN_002', 2, '2021-01-15', 250.00),
('ORDEN_003', 3, '2021-05-20', 0.00),
('ORDEN_004', 1, '2023-03-01', 240.0),
('ORDEN_005', 4, '2023-11-10', 25.00);

INSERT INTO proveedor (nombre, telefono) VALUES 
('Proveedor_1', '4444444444'),
('Proveedor_2', NULL),
('Proveedor_3', '5555555555');

INSERT INTO producto (nombre_producto, id_proveedor, precio_unitario, activo_sn) VALUES 
('producto_1', 1, 25.00, TRUE),
('producto_2', 2, 5500.00, TRUE),
('producto_3', 2, 250.00, TRUE),
('producto_4', 3, 80.00, FALSE),
('producto_5', 1, 1600.00, TRUE);

INSERT INTO detalle_orden (id_orden, id_producto, precio_unitario, cantidad) VALUES 
(1, 1, 25.00, 1),
(1, 2, 5500.00, 1),
(2, 3, 250.00, 1),
(4, 1,80.00, 3),
(5, 1, 25.00, 1);

--1. Número total de órdenes registradas.
SELECT COUNT(*) AS total_ordenes
FROM orden;

--2. Número de clientes que han realizado órdenes entre el 01-01-2021 y la fecha actual.
SELECT COUNT(DISTINCT cedula) AS clientes_con_ordenes
FROM orden
WHERE fecha_orden >= '2021-01-01' AND fecha_orden <= CURRENT_DATE;

--3. Listado total de clientes con la cantidad total de órdenes realizadas (conteo), ordenando de mayor a menor nro. de órdenes.
SELECT 
    c.cedula,
    c.nombre,
    COUNT(o.id_orden) AS total_ordenes
FROM cliente AS c
LEFT JOIN orden AS o ON c.cedula = o.cedula
GROUP BY c.cedula, c.nombre
ORDER BY total_ordenes DESC;

--4. Detalle completo (datos del cliente, fecha, nombre producto, cantidad) del pedido cuyo monto fue el más grande (en valor, no en unidades) en el año 2020.
SELECT 
	o.nro_orden,
    c.cedula,
    c.nombre AS nombre_cliente,
    o.fecha_orden,
    p.nombre_producto,
    d.cantidad,
    d.precio_unitario,
    o.total_pedido
FROM orden AS o
JOIN cliente AS c ON o.cedula = c.cedula
JOIN detalle_orden AS d ON o.id_orden = d.id_orden
JOIN producto AS p ON d.id_producto = p.id_producto
WHERE o.id_orden = (
    SELECT id_orden
    FROM orden
    WHERE EXTRACT(YEAR FROM fecha_orden) = 2020
    ORDER BY total_pedido DESC
    LIMIT 1
);

--5. Valor total vendido por mes y año.
SELECT 
    EXTRACT(YEAR FROM fecha_orden) AS anio,
    EXTRACT(MONTH FROM fecha_orden) AS mes,
    SUM(total_pedido) AS total_vendido
FROM orden
GROUP BY anio, mes
ORDER BY anio, mes;

--6. Para el cliente con cédula 123456, especificar para cada producto, el número de veces que lo ha comprado y el valor total gastado en dicho producto. Ordenar el resultado de mayor a menor.
SELECT 
    p.nombre_producto,
    SUM(d.cantidad) AS veces_comprado,  -- total de unidades compradas
    SUM(d.precio_unitario * d.cantidad) AS total_gastado
FROM cliente AS c
JOIN orden AS o ON c.cedula = o.cedula
JOIN detalle_orden AS d ON o.id_orden = d.id_orden
JOIN producto AS p ON d.id_producto = p.id_producto
WHERE c.cedula = 1
GROUP BY p.nombre_producto
ORDER BY total_gastado DESC;

--7. Si necesitas actualizar una tabla histórica con los datos del último mes, y en este nuevo mes has incluido una nueva columna para la ciudad del cliente, ¿qué proceso seguirías para evitar conflictos por diferencia de dimensiones, considerando que no tienes acceso a los comandos ADD COLUMN o ALTER TABLE?

-- RESPUESTA íTEM 7: Dado que no es posible modificar la estuctura de la tabla histórica, lo que haría sería crear una nueva tabla con la columa "ciudad". Insertaría los datos históricos, agregando valores nulos o un valor predeterminado en el campo "ciudad", y luego agregaría los datos nuevos que sí contienen este campo "ciudad".
