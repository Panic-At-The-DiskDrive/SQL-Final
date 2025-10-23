DROP DATABASE IF EXISTS beru_books;
CREATE DATABASE beru_books CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE beru_books;

DROP VIEW IF EXISTS vw_top_selling_books;
DROP VIEW IF EXISTS vw_sales_summary;
DROP VIEW IF EXISTS vw_customer_orders_summary;
DROP VIEW IF EXISTS vw_purchase_details;
DROP VIEW IF EXISTS vw_books_with_authors;

DROP TRIGGER IF EXISTS trg_payment_after_insert;
DROP TRIGGER IF EXISTS trg_order_item_after_delete;
DROP TRIGGER IF EXISTS trg_order_item_after_insert;

DROP PROCEDURE IF EXISTS sp_customer_purchases;
DROP PROCEDURE IF EXISTS sp_list_books;
DROP PROCEDURE IF EXISTS sp_sales_by_category;
DROP FUNCTION IF EXISTS fn_purchase_total;
DROP FUNCTION IF EXISTS fn_book_stock;

DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS shipment;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS discount;
DROP TABLE IF EXISTS address;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS audit_log;

CREATE TABLE audit_log (
audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
table_name VARCHAR(100) NOT NULL,
pk_name VARCHAR(100) NOT NULL,
pk_value VARCHAR(255) NOT NULL,
action ENUM('INSERT','UPDATE','DELETE') NOT NULL,
changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
changed_by VARCHAR(100) DEFAULT NULL,
old_row JSON DEFAULT NULL,
new_row JSON DEFAULT NULL,
INDEX idx_audit_table_name (table_name),
INDEX idx_audit_pk (pk_name, pk_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE customer (
customer_id INT AUTO_INCREMENT PRIMARY KEY,
username VARCHAR(50) NOT NULL UNIQUE,
email VARCHAR(100) NOT NULL UNIQUE,
password_hash VARCHAR(255) NOT NULL,
role ENUM('customer','admin') NOT NULL DEFAULT 'customer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE employee (
employee_id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
position VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE address (
address_id INT AUTO_INCREMENT PRIMARY KEY,
customer_id INT NOT NULL,
street VARCHAR(200),
city VARCHAR(100),
province VARCHAR(100),
zip VARCHAR(20),
CONSTRAINT fk_address_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE supplier (
supplier_id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(150) NOT NULL,
contact_email VARCHAR(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE author (
author_id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
bio TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE category (
category_id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE discount (
discount_id INT AUTO_INCREMENT PRIMARY KEY,
code VARCHAR(50) UNIQUE,
description VARCHAR(255),
percent DECIMAL(5,2) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE book (
book_id INT AUTO_INCREMENT PRIMARY KEY,
title VARCHAR(200) NOT NULL,
description TEXT,
price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
stock INT NOT NULL DEFAULT 0,
author_id INT,
category_id INT,
supplier_id INT,
discount_id INT,
CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author(author_id) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT fk_book_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT fk_book_discount FOREIGN KEY (discount_id) REFERENCES discount(discount_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchase (
purchase_id INT AUTO_INCREMENT PRIMARY KEY,
customer_id INT NOT NULL,
status ENUM('pending','paid','shipped','cancelled') NOT NULL DEFAULT 'pending',
total DECIMAL(12,2) NOT NULL DEFAULT 0,
discount_id INT,
CONSTRAINT fk_purchase_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
CONSTRAINT fk_purchase_discount FOREIGN KEY (discount_id) REFERENCES discount(discount_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_item (
order_item_id INT AUTO_INCREMENT PRIMARY KEY,
purchase_id INT NOT NULL,
book_id INT NOT NULL,
quantity INT NOT NULL CHECK (quantity > 0),
price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
CONSTRAINT fk_oi_purchase FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_oi_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE payment (
payment_id INT AUTO_INCREMENT PRIMARY KEY,
purchase_id INT NOT NULL,
method ENUM('card','transfer','cash') NOT NULL,
amount DECIMAL(12,2) NOT NULL,
paid_at TIMESTAMP NULL,
CONSTRAINT fk_payment_purchase FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE shipment (
shipment_id INT AUTO_INCREMENT PRIMARY KEY,
purchase_id INT NOT NULL,
carrier VARCHAR(100),
tracking_code VARCHAR(100),
shipped_at TIMESTAMP NULL,
delivered_at TIMESTAMP NULL,
CONSTRAINT fk_shipment_purchase FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE review (
review_id INT AUTO_INCREMENT PRIMARY KEY,
book_id INT NOT NULL,
customer_id INT NOT NULL,
rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
comment TEXT,
CONSTRAINT fk_review_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_review_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inventory (
inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,
book_id INT NOT NULL,
supplier_id INT,
employee_id INT,
movement_type ENUM('IN','OUT','ADJUST') NOT NULL,
quantity INT NOT NULL,
movement_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
notes VARCHAR(255),
CONSTRAINT fk_inventory_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_inventory_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT fk_inventory_employee FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP VIEW IF EXISTS vw_books_with_authors;
CREATE VIEW vw_books_with_authors AS
SELECT b.book_id, b.title, b.price, b.stock,
a.author_id, a.name AS author_name,
c.category_id, c.name AS category_name,
s.supplier_id, s.name AS supplier_name,
d.discount_id, d.code AS discount_code
FROM book b
LEFT JOIN author a ON b.author_id = a.author_id
LEFT JOIN category c ON b.category_id = c.category_id
LEFT JOIN supplier s ON b.supplier_id = s.supplier_id
LEFT JOIN discount d ON b.discount_id = d.discount_id;

DROP VIEW IF EXISTS vw_purchase_details;
CREATE VIEW vw_purchase_details AS
SELECT p.purchase_id, p.customer_id, c.username, p.status, p.total,
oi.order_item_id, oi.book_id, b.title AS book_title, oi.quantity, oi.price
FROM purchase p
JOIN customer c ON p.customer_id = c.customer_id
JOIN order_item oi ON oi.purchase_id = p.purchase_id
JOIN book b ON b.book_id = oi.book_id;

DROP VIEW IF EXISTS vw_customer_orders_summary;
CREATE VIEW vw_customer_orders_summary AS
SELECT c.customer_id, c.username, COUNT(p.purchase_id) AS total_orders,
SUM(p.total) AS total_spent
FROM customer c
LEFT JOIN purchase p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.username;

DROP VIEW IF EXISTS vw_sales_summary;
CREATE VIEW vw_sales_summary AS
SELECT DATE(purchase_at) AS sale_date, b.category_id, cat.name AS category, COUNT(oi.order_item_id) AS items_sold, SUM(oi.quantity*oi.price) AS revenue
FROM purchase p
JOIN order_item oi ON oi.purchase_id = p.purchase_id
JOIN book b ON b.book_id = oi.book_id
LEFT JOIN category cat ON b.category_id = cat.category_id
LEFT JOIN (SELECT purchase_id, MIN(paid_at) AS purchase_at FROM payment GROUP BY purchase_id) pay ON pay.purchase_id = p.purchase_id
GROUP BY sale_date, b.category_id, cat.name;

DROP VIEW IF EXISTS vw_top_selling_books;
CREATE VIEW vw_top_selling_books AS
SELECT b.book_id, b.title, SUM(oi.quantity) AS total_sold
FROM order_item oi
JOIN book b ON b.book_id = oi.book_id
GROUP BY b.book_id, b.title
ORDER BY total_sold DESC
LIMIT 10;

DELIMITER $$

CREATE FUNCTION fn_book_stock(p_book_id INT) 
RETURNS INT 
DETERMINISTIC
BEGIN
  DECLARE v_stock INT DEFAULT 0;
  SELECT COALESCE(stock,0) INTO v_stock 
  FROM book 
  WHERE book_id = p_book_id;
  RETURN v_stock;
END$$

DELIMITER ;

CREATE FUNCTION fn_purchase_total(p_purchase_id INT) RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
DECLARE v_total DECIMAL(12,2) DEFAULT 0;
SELECT COALESCE(SUM(quantity * price), 0) INTO v_total FROM order_item WHERE purchase_id = p_purchase_id;
RETURN v_total;
END$$

CREATE PROCEDURE sp_list_books()
BEGIN
SELECT b.book_id, b.title, b.price, b.stock, a.name AS author, c.name AS category, s.name AS supplier
FROM book b
LEFT JOIN author a ON b.author_id = a.author_id
LEFT JOIN category c ON b.category_id = c.category_id
LEFT JOIN supplier s ON b.supplier_id = s.supplier_id
ORDER BY b.title;
END$$

CREATE PROCEDURE sp_customer_purchases(IN p_customer_id INT)
BEGIN
SELECT p.purchase_id, p.status, p.total, COUNT(oi.order_item_id) AS items_count
FROM purchase p
LEFT JOIN order_item oi ON oi.purchase_id = p.purchase_id
WHERE p.customer_id = p_customer_id
GROUP BY p.purchase_id, p.status, p.total;
END$$

CREATE PROCEDURE sp_sales_by_category(IN p_category_id INT)
BEGIN
SELECT cat.category_id, cat.name, SUM(oi.quantity*oi.price) AS revenue, COUNT(DISTINCT p.purchase_id) AS orders_count
FROM order_item oi
JOIN book b ON b.book_id = oi.book_id
JOIN purchase p ON p.purchase_id = oi.purchase_id
JOIN category cat ON cat.category_id = b.category_id
WHERE cat.category_id = p_category_id
GROUP BY cat.category_id, cat.name;
END$$

CREATE PROCEDURE sp_add_order_item(IN p_purchase_id INT, IN p_book_id INT, IN p_qty INT, IN p_price DECIMAL(12,2))
BEGIN
DECLARE v_stock INT;
SELECT stock INTO v_stock FROM book WHERE book_id = p_book_id FOR UPDATE;
IF v_stock IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book does not exist'; END IF;
IF v_stock < p_qty THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock'; END IF;
INSERT INTO order_item (purchase_id, book_id, quantity, price) VALUES (p_purchase_id, p_book_id, p_qty, p_price);
UPDATE book SET stock = stock - p_qty WHERE book_id = p_book_id;
UPDATE purchase SET total = fn_purchase_total(p_purchase_id) WHERE purchase_id = p_purchase_id;
END$$

CREATE TRIGGER trg_order_item_after_insert
AFTER INSERT ON order_item
FOR EACH ROW
BEGIN
UPDATE book SET stock = stock - NEW.quantity WHERE book_id = NEW.book_id;
INSERT INTO audit_log (table_name, pk_name, pk_value, action, new_row)
VALUES ('order_item','order_item_id',CAST(NEW.order_item_id AS CHAR),'INSERT',
JSON_OBJECT('order_item_id', NEW.order_item_id,'purchase_id', NEW.purchase_id,'book_id', NEW.book_id,'quantity', NEW.quantity,'price', NEW.price));
END$$

CREATE TRIGGER trg_order_item_after_delete
AFTER DELETE ON order_item
FOR EACH ROW
BEGIN
UPDATE book SET stock = stock + OLD.quantity WHERE book_id = OLD.book_id;
INSERT INTO audit_log (table_name, pk_name, pk_value, action, old_row)
VALUES ('order_item','order_item_id',CAST(OLD.order_item_id AS CHAR),'DELETE',
JSON_OBJECT('order_item_id', OLD.order_item_id,'purchase_id', OLD.purchase_id,'book_id', OLD.book_id,'quantity', OLD.quantity,'price', OLD.price));
END$$

CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
UPDATE purchase SET status = 'paid', total = fn_purchase_total(NEW.purchase_id) WHERE purchase_id = NEW.purchase_id;
INSERT INTO audit_log (table_name, pk_name, pk_value, action, new_row)
VALUES ('payment','payment_id',CAST(NEW.payment_id AS CHAR),'INSERT',
JSON_OBJECT('payment_id', NEW.payment_id,'purchase_id', NEW.purchase_id,'amount', NEW.amount,'method', NEW.method,'paid_at', IFNULL(DATE_FORMAT(NEW.paid_at, '%Y-%m-%d %H:%i:%s'), NULL)));
END$$
DELIMITER ;

INSERT INTO employee (name, position) VALUES
('Ana López','Warehouse'),
('Pedro García','Logistics'),
('Lucía Fernández','Sales'),
('Diego Ramírez','Support'),
('Mariana Torres','Purchasing'),
('Santiago Díaz','IT'),
('Carolina Ruiz','Marketing'),
('Federico Alvarez','Manager');

INSERT INTO supplier (name, contact_email) VALUES
('Editorial Norte','norte@editorial.com
'),
('Sur Libros','sur@libros.com
'),
('Andes Press','andes@press.com
'),
('Delta Editorial','delta@editorial.com
'),
('Plaza & Janés','plaza@editorial.com
'),
('Siglo Veintiuno','siglo@editorial.com
'),
('Emecé','emece@editorial.com
'),
('Tusquets','tusquets@editorial.com
');

INSERT INTO author (name, bio) VALUES
('Jorge Luis Borges','Escritor argentino, maestro del cuento'),
('Julio Cortázar','Novelista y cuentista argentino'),
('Ernesto Sabato','Autor de El túnel'),
('Adolfo Bioy Casares','Autor de La invención de Morel'),
('Silvina Ocampo','Poeta y cuentista argentina'),
('Manuel Puig','Autor de Boquitas pintadas'),
('Rodolfo Walsh','Periodista y escritor'),
('Ricardo Piglia','Ensayista y narrador argentino');

INSERT INTO category (name) VALUES
('Ficción'),('Poesía'),('Ensayo'),('Misterio'),
('Ciencia Ficción'),('Drama'),('Histórico'),('Biografía');

INSERT INTO discount (code, description, percent) VALUES
('OF10','Descuento 10%',10.00),
('OF15','Descuento 15%',15.00),
('LIBRO5','Descuento libro 5%',5.00),
('SUMMER20','Oferta verano 20%',20.00),
('STUDENT','Descuento estudiantes 12%',12.00),
('VIP25','VIP 25%',25.00),
('CLEAR30','Liquidación 30%',30.00),
('WELCOME5','Bienvenida 5%',5.00);

INSERT INTO book (title, description, price, stock, author_id, category_id, supplier_id, discount_id) VALUES
('Ficciones','Cuentos de Borges',3500.00,50,1,1,1,1),
('Rayuela','Novela de Cortázar',4200.00,40,2,1,2,2),
('El túnel','Novela psicológica',3000.00,30,3,6,3,3),
('La invención de Morel','Fantasía filosófica',2800.00,25,4,5,4,4),
('Poemas','Antología poética',2200.00,60,5,2,5,5),
('Boquitas pintadas','Novela coral',3900.00,35,6,6,6,6),
('Operación masacre','Crónica testimonial',4500.00,20,7,3,7,7),
('Respiración artificial','Ficción política',4100.00,15,8,1,8,8);

INSERT INTO customer (username, email, password_hash, role) VALUES
('danielle','danielle@example.com
','hash1','admin'),
('juan','juan@example.com
','hash2','customer'),
('maria','maria@example.com
','hash3','customer'),
('sofia','sofia@example.com
','hash4','customer'),
('lucas','lucas@example.com
','hash5','customer'),
('valentina','valentina@example.com
','hash6','customer'),
('martin','martin@example.com
','hash7','customer'),
('carla','carla@example.com
','hash8','customer');

INSERT INTO address (customer_id, street, city, province, zip) VALUES
(1,'Av. Corrientes 1234','CABA','CABA','1043'),
(2,'Santa Fe 200','Rosario','Santa Fe','2000'),
(3,'Mendoza 456','Mendoza','Mendoza','5500'),
(4,'San Martín 78','La Plata','Buenos Aires','1900'),
(5,'Belgrano 55','CABA','CABA','1064'),
(6,'Rivadavia 900','Mar del Plata','Buenos Aires','7600'),
(7,'Mitre 333','Córdoba','Córdoba','5000'),
(8,'Urquiza 101','Bahía Blanca','Buenos Aires','8000');

INSERT INTO purchase (customer_id, status, total, discount_id) VALUES
(2,'pending',0,1),(3,'paid',0,2),(4,'pending',0,3),(5,'cancelled',0,4),
(6,'paid',0,5),(7,'pending',0,6),(8,'pending',0,7),(1,'shipped',0,8);

INSERT INTO order_item (purchase_id, book_id, quantity, price) VALUES
(1,1,1,3500.00),(1,2,1,4200.00),(2,3,2,3000.00),(3,4,1,2800.00),
(4,5,3,2200.00),(5,6,2,3900.00),(6,7,1,4500.00),(7,8,1,4100.00);

INSERT INTO payment (purchase_id, method, amount, paid_at) VALUES
(2,'card',6000.00,NOW() - INTERVAL 2 DAY),(6,'transfer',4500.00,NOW() - INTERVAL 1 DAY),
(5,'card',7800.00,NOW() - INTERVAL 10 DAY),(8,'cash',4100.00,NULL),
(1,'card',7700.00,NOW() - INTERVAL 5 HOUR),(3,'transfer',2800.00,NOW() - INTERVAL 3 DAY),
(4,'card',6600.00,NOW() - INTERVAL 20 HOUR),(7,'card',4100.00,NOW() - INTERVAL 7 DAY);

INSERT INTO shipment (purchase_id, carrier, tracking_code, shipped_at, delivered_at) VALUES
(1,'Correo Argentino','AR123','2025-09-10 10:00:00','2025-09-12 15:00:00'),
(2,'Andreani','AN234','2025-09-08 09:00:00','2025-09-10 11:30:00'),
(3,'DHL','DH345',NULL,NULL),
(4,'Correo Argentino','AR456',NULL,NULL),
(5,'Andreani','AN567','2025-09-05 14:00:00','2025-09-07 16:00:00'),
(6,'DHL','DH678',NULL,NULL),
(7,'Correo Argentino','AR789',NULL,NULL),
(8,'Andreani','AN890','2025-09-09 12:00:00',NULL);

INSERT INTO review (book_id, customer_id, rating, comment) VALUES
(1,2,5,'Impresionante colección'),(2,3,4,'Me gustó mucho'),(3,4,4,'Recomendable'),
(4,5,3,'Interesante concepto'),(5,6,5,'Excelente selección'),(6,7,4,'Buena lectura'),
(7,8,5,'Impactante'),(8,1,4,'Muy entretenido');

INSERT INTO inventory (book_id, supplier_id, employee_id, movement_type, quantity, notes) VALUES
(1,1,1,'IN',100,'Ingreso inicial'),(2,2,2,'IN',80,'Ingreso inicial'),(3,3,3,'IN',60,'Ingreso inicial'),
(4,4,4,'IN',50,'Ingreso inicial'),(5,5,5,'IN',120,'Ingreso inicial'),(6,6,6,'IN',70,'Ingreso inicial'),
(7,7,7,'IN',40,'Ingreso inicial'),(8,8,8,'IN',30,'Ingreso inicial');

INSERT INTO inventory (book_id, supplier_id, employee_id, movement_type, quantity, notes) VALUES
(1,1,1,'OUT',10,'Venta inicial'),(2,2,2,'OUT',5,'Venta inicial'),(3,3,3,'OUT',8,'Venta inicial'),
(4,4,4,'OUT',3,'Venta inicial'),(5,5,5,'OUT',12,'Venta inicial'),(6,6,6,'OUT',7,'Venta inicial'),
(7,7,7,'OUT',4,'Venta inicial'),(8,8,8,'OUT',6,'Venta inicial');

UPDATE book SET stock = stock - (SELECT COALESCE(SUM(quantity),0) FROM order_item WHERE order_item.book_id = book.book_id);

SELECT COUNT(*) AS customers_count FROM customer;
SELECT * FROM book LIMIT 10;
SELECT * FROM purchase LIMIT 10;
SELECT * FROM order_item LIMIT 20;
SELECT * FROM payment LIMIT 20;
SELECT * FROM shipment LIMIT 20;
SELECT * FROM inventory LIMIT 20;
SELECT * FROM vw_books_with_authors LIMIT 20;
SELECT * FROM vw_purchase_details LIMIT 20;
SELECT * FROM vw_customer_orders_summary LIMIT 20;
SELECT * FROM vw_sales_summary LIMIT 20;
SELECT * FROM vw_top_selling_books LIMIT 20;
SELECT * FROM audit_log ORDER BY changed_at DESC LIMIT 20;



