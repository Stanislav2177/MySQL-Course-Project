DROP DATABASE hypermarket;
CREATE DATABASE hypermarket;
USE hypermarket;

-- Task 1, Design a database and present an ER diagram with corresponding CREATE TABLE statements for the MySQL environment.

CREATE TABLE departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  department_name VARCHAR(50) NOT NULL,
  manager_id INT NOT NULL
);

CREATE TABLE managers (
  manager_id INT AUTO_INCREMENT PRIMARY KEY,
  manager_name VARCHAR(50) NOT NULL,
  department_id INT NOT NULL,
  contact_info VARCHAR(50) NOT NULL,
  FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE employees (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  employee_name VARCHAR(50) NOT NULL,
  position VARCHAR(50) NOT NULL,
  department_id INT NOT NULL,
  manager_id INT NOT NULL,
  contact_info VARCHAR(50) NOT NULL,
  FOREIGN KEY (department_id) REFERENCES departments(department_id),
  FOREIGN KEY (manager_id) REFERENCES managers(manager_id)
);

CREATE TABLE manufacturers (
  manufacturer_id INT AUTO_INCREMENT PRIMARY KEY,
  manufacturer_name VARCHAR(50) NOT NULL,
  country VARCHAR(50) NOT NULL,
  contact_info VARCHAR(50) NOT NULL
);

CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  product_name VARCHAR(50) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  expiry_date DATE NOT NULL,
  manufacturer_id INT NOT NULL,
  quantity int NOT NULL,
  FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(manufacturer_id)
);

CREATE TABLE sales (
  sale_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_date DATE NOT NULL,
  sale_time TIME NOT NULL,
  employee_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  order_date DATE NOT NULL,
  supplier_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  expected_delivery_date DATE NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO departments (department_name, manager_id) VALUES
("Sales", 1),
("Finance", 2),
("Supply", 3);

INSERT INTO managers (manager_name, department_id, contact_info) VALUES
("Stanislav Yankov", 1, "088-555-4141"),
("John Doe", 2, "089-123-4242"),
("Evgeni", 3,"089-124-5555");

INSERT INTO employees (employee_name, position, department_id, manager_id, contact_info) VALUES
("Martin", "Seller", 1, 1, "088-124-4432"),
("Kaloyan", "Seller", 1, 1, "088-312-4432"),
("Vencislav", "Seller", 1, 1, "088-442-1224"),
("Daniel", "Seller", 1, 1, "089-232-4432"),
("Valentin", "Financial Advisor", 2, 2, "088-124-4432"),
("Kristian", "Loader", 3, 3, "088-535-3343"),
("Martin", "Heaver", 3, 3, "088-211-4311");


INSERT INTO manufacturers (manufacturer_name, country, contact_info) VALUES 
('ABC Inc.', 'USA', 'info@abc.com'),
('XYZ Corp.', 'Japan', 'info@xyz.co.jp'),
('DEF Ltd.', 'Germany', 'info@def.de');


INSERT INTO products (product_name, price, expiry_date, manufacturer_id, quantity) VALUES 
('Product 1', 20.99, '2023-06-30', 1, 50),
('Product 2', 15.49, '2024-01-31', 2, 50),
('Product 3', 10.99, '2023-12-31', 1, 50),
('Product 4', 7.99, '2023-09-30', 3, 50),
('Product 5', 5.49, '2024-03-31', 2, 50);

INSERT INTO sales (sale_date, sale_time, employee_id, product_id, quantity) VALUES 
('2023-04-01', '14:30:00', 1, 1, 5),
('2023-04-02', '11:45:00', 2, 3, 3),
('2023-04-03', '10:15:00', 4, 2, 2),
('2023-04-03', '16:00:00', 5, 4, 10),
('2023-04-04', '13:20:00', 1, 5, 8);


ALTER TABLE departments
ADD
FOREIGN KEY (manager_id) REFERENCES managers(manager_id);

-- Task 2, Write select query with a optional limiting condition.

SELECT employees.employee_name AS employee, departments.department_name AS department, managers.manager_name AS manager
FROM employees
JOIN departments
JOIN managers WHERE managers.manager_id = 1 AND departments.department_id = 1;

-- Task 3, Write a query which to shows agregate function and group by

SELECT employees.employee_name as employeer, COUNT(sales.employee_id) AS employees_sales
FROM employees
JOIN sales ON sales.employee_id = employees.employee_id
GROUP BY sales.employee_id;

-- Task 4, Write a query which to demonstrate INNER JOIN

SELECT manufacturers.manufacturer_name AS Manufacturer, products.product_name As Product_Name, 
sales.employee_id AS Employee_Id, employees.employee_name AS Employer
FROM manufacturers
JOIN products ON products.manufacturer_id = manufacturers.manufacturer_id
JOIN sales ON sales.product_id = products.product_id
JOIN employees ON employees.employee_id = sales.employee_id;

-- Task 5, Write a query which to demonstrate OUTER JOIN

SELECT departments.department_name, managers.manager_name, employees.employee_name
FROM departments
LEFT OUTER JOIN managers ON departments.department_id = managers.department_id
LEFT OUTER JOIN employees ON departments.department_id = employees.department_id;

-- Task 6, Write a query which to demonstrate Inner SELECT

SELECT e.employee_name, s.sale_date, s.product_id, s.quantity
FROM employees e
INNER JOIN sales s ON e.employee_id = s.employee_id
WHERE e.department_id = (
  SELECT department_id FROM departments WHERE department_name = 'Sales'
);


-- Task 7, Write a query that demonstrates both a JOIN and an aggregate function.

SELECT departments.department_name AS Department, 
       COUNT(sales.product_id) AS TotalProductsSold, 
       SUM(sales.quantity) AS TotalQuantitySold
FROM departments
JOIN (
  SELECT employees.employee_id, employees.department_id
  FROM employees
) AS dept_employees ON dept_employees.department_id = departments.department_id
JOIN sales ON sales.employee_id = dept_employees.employee_id
GROUP BY departments.department_name;

-- Task 8, Write a trigger
-- The trigger would check the expect_delivery_date from orders and if is below current date
-- error will appear

DELIMITER |
CREATE TRIGGER orders_before_insert
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
  IF NEW.expected_delivery_date < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Expected delivery date cannot be in the past';
  END IF;
END;
|
DELIMITER ;

INSERT INTO orders(order_date, supplier_id, product_id, quantity, expected_delivery_date) 
VALUES("2021-05-06", 1, 3, 50, "2023-03-04");

-- Task 9, Create a procedure that demonstrate the usage of cursor

DROP PROCEDURE get_department_manager_names;

DELIMITER |

CREATE PROCEDURE get_department_manager_names ()
BEGIN
    DECLARE finished INT;
    DECLARE dept_name VARCHAR(50);
    DECLARE manager_name VARCHAR(50);

    DECLARE depart_manager CURSOR FOR
        SELECT departments.department_name, managers.manager_name
        FROM departments
        JOIN managers ON departments.department_id = managers.department_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    OPEN depart_manager;

	CREATE temporary TABLE tempTbl(
    department varchar(30),
    manager varchar(30)) engine = Memory;
    
    read_loop: LOOP
    FETCH depart_manager INTO dept_name, manager_name;
    IF(finished = 1)
    THEN LEAVE read_loop;
    ELSE INSERT INTO tempTbl(department, manager) VALUES (dept_name, manager_name);
    END IF;
    END LOOP;
    
    SELECT * FROM tempTbl;
    CLOSE depart_manager;
    DROP TEMPORARY TABLE IF EXISTS tempTbl;
END;
|
DELIMITER ;

CALL get_department_manager_names;

DROP table accounts;

CREATE TABLE accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  role_user ENUM('ADMIN', 'USER'),
  password VARCHAR(255)
);

INSERT INTO accounts (first_name, last_name, email, role_user, password)
VALUES ("Stanislav", "Yankov", "stanislav2177@gmail.com", "Admin", "34153");

-- Additiononal procedures 
DELIMITER //

CREATE PROCEDURE GetSalesInfo()
BEGIN
    SELECT
        p.product_id,
        p.product_name,
        p.price,
        p.expiry_date,
        p.quantity AS product_quantity,
        s.sale_id,
        s.sale_date,
        s.sale_time,
        s.quantity AS sale_quantity,
        e.employee_id,
        e.employee_name,
        e.position,
        m.manufacturer_id,
        m.manufacturer_name,
        m.country,
        m.contact_info AS manufacturer_contact_info
    FROM products p
    INNER JOIN sales s ON p.product_id = s.product_id
    INNER JOIN employees e ON s.employee_id = e.employee_id
    INNER JOIN manufacturers m ON p.manufacturer_id = m.manufacturer_id;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE GetSalesInfoFiltered(IN product_id_param INT)
BEGIN
    SELECT
        p.product_id,
        p.product_name,
        p.price,
        p.expiry_date,
        p.quantity AS product_quantity,
        s.sale_id,
        s.sale_date,
        s.sale_time,
        s.quantity AS sale_quantity,
        e.employee_id,
        e.employee_name,
        e.position,
        m.manufacturer_id,
        m.manufacturer_name,
        m.country,
        m.contact_info AS manufacturer_contact_info
    FROM products p
    INNER JOIN sales s ON p.product_id = s.product_id
    INNER JOIN employees e ON s.employee_id = e.employee_id
    INNER JOIN manufacturers m ON p.manufacturer_id = m.manufacturer_id
    WHERE p.product_id = product_id_param;
END //

DELIMITER ;
CALL GetSalesInfoFiltered(2); 



SELECT * FROM managers;
select * FROM products;