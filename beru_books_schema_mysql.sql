DROP DATABASE IF EXISTS `beru_books`;
CREATE DATABASE `beru_books` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `beru_books`;

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

DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS customer;

CREATE TABLE customer (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','admin') NOT NULL DEFAULT 'customer'
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

CREATE TABLE book (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  stock INT NOT NULL DEFAULT 0,
  author_id INT,
  category_id INT,
  CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author(author_id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchase (
  purchase_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  status ENUM('pending','paid','shipped','cancelled') NOT NULL DEFAULT 'pending',
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_purchase_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE
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

DROP VIEW IF EXISTS vw_books_with_authors;
CREATE VIEW vw_books_with_authors AS
SELECT b.book_id, b.title, b.price, b.stock,
       a.author_id, a.name AS author_name,
       c.category_id, c.name AS category_name
FROM book b
LEFT JOIN author a ON b.author_id = a.author_id
LEFT JOIN category c ON b.category_id = c.category_id;

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

DELIMITER $$

DROP FUNCTION IF EXISTS fn_book_stock$$
CREATE FUNCTION fn_book_stock(p_book_id INT) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_stock INT DEFAULT 0;
  SELECT COALESCE(stock,0) INTO v_stock FROM book WHERE book_id = p_book_id;
  RETURN v_stock;
END$$

DROP FUNCTION IF EXISTS fn_purchase_total$$
CREATE FUNCTION fn_purchase_total(p_purchase_id INT) RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  SELECT COALESCE(SUM(quantity * price), 0) INTO v_total FROM order_item WHERE purchase_id = p_purchase_id;
  RETURN v_total;
END$$

DROP PROCEDURE IF EXISTS sp_list_books$$
CREATE PROCEDURE sp_list_books()
BEGIN
  SELECT b.book_id, b.title, b.price, b.stock, a.name AS author, c.name AS category
  FROM book b
  JOIN author a ON b.author_id = a.author_id
  JOIN category c ON b.category_id = c.category_id
  ORDER BY b.title;
END$$

DROP PROCEDURE IF EXISTS sp_customer_purchases$$
CREATE PROCEDURE sp_customer_purchases(IN p_customer_id INT)
BEGIN
  SELECT p.purchase_id, p.status, p.total, COUNT(oi.order_item_id) AS items_count
  FROM purchase p
  LEFT JOIN order_item oi ON oi.purchase_id = p.purchase_id
  WHERE p.customer_id = p_customer_id
  GROUP BY p.purchase_id, p.status, p.total;
END$$

DROP PROCEDURE IF EXISTS sp_add_order_item$$
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

DROP PROCEDURE IF EXISTS sp_recalculate_purchase_total$$
CREATE PROCEDURE sp_recalculate_purchase_total(IN p_purchase_id INT)
BEGIN
  UPDATE purchase SET total = fn_purchase_total(p_purchase_id) WHERE purchase_id = p_purchase_id;
END$$

DROP TRIGGER IF EXISTS trg_order_item_after_insert$$
CREATE TRIGGER trg_order_item_after_insert
AFTER INSERT ON order_item
FOR EACH ROW
BEGIN
  UPDATE book SET stock = stock - NEW.quantity WHERE book_id = NEW.book_id;
  INSERT INTO audit_log (table_name, pk_name, pk_value, action, new_row)
  VALUES ('order_item','order_item_id',CAST(NEW.order_item_id AS CHAR),'INSERT',
          JSON_OBJECT('order_item_id', NEW.order_item_id,'purchase_id', NEW.purchase_id,'book_id', NEW.book_id,'quantity', NEW.quantity,'price', NEW.price));
END$$

DROP TRIGGER IF EXISTS trg_order_item_after_delete$$
CREATE TRIGGER trg_order_item_after_delete
AFTER DELETE ON order_item
FOR EACH ROW
BEGIN
  UPDATE book SET stock = stock + OLD.quantity WHERE book_id = OLD.book_id;
  INSERT INTO audit_log (table_name, pk_name, pk_value, action, old_row)
  VALUES ('order_item','order_item_id',CAST(OLD.order_item_id AS CHAR),'DELETE',
          JSON_OBJECT('order_item_id', OLD.order_item_id,'purchase_id', OLD.purchase_id,'book_id', OLD.book_id,'quantity', OLD.quantity,'price', OLD.price));
END$$

DELIMITER ;

INSERT INTO customer (username, email, password_hash, role) VALUES
('daniel','daniel@coder.com','hash1','admin'),
('juan','juan@coder.com','hash2','customer'),
('maria','maria@coder.com','hash3','customer'),
('sofia','sofia@coder.com','hash4','customer'),
('lucas','lucas@coder.com','hash5','customer'),
('valentina','valentina@coder.com','hash6','customer'),
('martin','martin@coder.com','hash7','customer'),
('carla','carla@coder.com','hash8','customer');

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

INSERT INTO book (title, description, price, stock, author_id, category_id) VALUES
('Ficciones','Cuentos de Borges',3500.00,10,1,1),
('Rayuela','Novela de Cortázar',4200.00,5,2,1),
('El túnel','Novela psicológica',3000.00,8,3,6),
('La invención de Morel','Fantasía filosófica',2800.00,6,4,5),
('Poemas','Antología poética',2200.00,10,5,2),
('Boquitas pintadas','Novela coral',3900.00,7,6,6),
('Operación masacre','Crónica testimonial',4500.00,4,7,3),
('Respiración artificial','Ficción política',4100.00,5,8,1);

INSERT INTO purchase (customer_id, status, total) VALUES
(2,'pending',0),(3,'paid',0),(4,'pending',0),(5,'cancelled',0),
(6,'paid',0),(7,'pending',0),(8,'pending',0),(1,'shipped',0);

INSERT INTO order_item (purchase_id, book_id, quantity, price) VALUES
(1,1,1,3500.00),(1,2,1,4200.00),(2,3,2,3000.00),(3,4,1,2800.00),
(4,5,3,2200.00),(5,6,2,3900.00),(6,7,1,4500.00),(7,8,1,4100.00);

SELECT COUNT(*) AS customers_count FROM customer;
SELECT * FROM book LIMIT 10;
SELECT * FROM purchase LIMIT 10;
SELECT * FROM order_item LIMIT 20;
SELECT * FROM vw_books_with_authors LIMIT 20;
SELECT * FROM vw_purchase_details LIMIT 20;
SELECT * FROM vw_customer_orders_summary LIMIT 20;
SELECT * FROM audit_log ORDER BY changed_at DESC LIMIT 20;



