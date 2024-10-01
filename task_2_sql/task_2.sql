
-- Счета
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,	  -- Уникальный идентификатор счета
    invoice_number VARCHAR(50),       -- Номер счета
    manager_id INT NOT NULL,          -- ID менеджера, который выставил счет
    contractor_id INT NOT NULL,       -- ID контрагента, которому выставлен счет
    issue_date DATE NOT NULL,         -- Дата выставления счета
    total_amount DECIMAL(15, 2),      -- Общая сумма счета
    status VARCHAR(20),               -- Статус счета (например, 'выставлен', 'отменен')
    description TEXT,                 -- Дополнительное описание или комментарий к счету
	payment_status VARCHAR(20),		      -- Статус оплаты (например, 'Полная', 'Частичная', 'Не оплачена')
	shipment_status VARCHAR(20), 	      -- Статус отгрузки (например, 'Отгружено', 'Частично отгружено', 'Не отгружено')
	last_synced TIMESTAMP         	    -- Время последней синхронизации со внешней системой

);


-- Позиции счета
CREATE TABLE invoice_items (
    item_id SERIAL PRIMARY KEY,    -- Уникальный идентификатор позиции счета
    invoice_id INT NOT NULL,       -- ID счета, к которому принадлежит позиция
    product_name VARCHAR(100),     -- Наименование товара или услуги
    quantity INT NOT NULL,         -- Количество товара или услуги
    unit_price DECIMAL(10, 2),     -- Цена за единицу товара или услуги
    total_price DECIMAL(15, 2)     -- Общая стоимость по данной позиции (quantity * unit_price)
);


-- Менеджеры
CREATE TABLE managers (
    manager_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор менеджера
    name VARCHAR(100) NOT NULL,     -- Имя менеджера
    email VARCHAR(100) NOT NULL,	  -- Электронная почта менеджера
    phone VARCHAR(20) NOT NULL		  -- Номер телефона менеджера
);


-- Контрагенты
CREATE TABLE contractors (
    contractor_id SERIAL PRIMARY KEY,   -- Уникальный идентификатор контрагента
    name VARCHAR(100) NOT NULL,         -- Имя менеджера
    email VARCHAR(100) NOT NULL,	      -- Электронная почта менеджера
    phone VARCHAR(20) NOT NULL		      -- Номер телефона менеджера
);


-- Индекс для быстрого поиска счетов по номеру
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);

-- Индекс для поиска счетов по дате выставления
CREATE INDEX idx_invoices_issue_date ON invoices(issue_date);

-- Индекс для поиска счетов по ID менеджера
CREATE INDEX idx_invoices_manager_id ON invoices(manager_id);

-- Индекс для поиска счетов по ID контрагента
CREATE INDEX idx_invoices_contractor_id ON invoices(contractor_id);

-- Индекс для связки позиций с соответствующими счетами
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);


-- Индекс для быстрого поиска по статусу оплаты
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);

-- Индекс для быстрого поиска по статусу отгрузки
CREATE INDEX idx_invoices_shipment_status ON invoices(shipment_status);

-- Индекс для отслеживания счетов, требующих синхронизации
CREATE INDEX idx_invoices_last_synced ON invoices(last_synced);


-- Выборка последних 20 счетов, выставленных менеджером
SELECT i.invoice_id
	, i.invoice_number
	, i.issue_date
	, i.total_amount
	, i.status
	, c.name AS contractor_name
FROM invoices i
JOIN contractors c ON i.contractor_id = c.contractor_id
WHERE i.manager_id = :manager_id -- Замените :manager_id на нужный ID менеджера
ORDER BY i.issue_date DESC
LIMIT 20;


-- Поиск счетов, выставленных за прошлую неделю, месяц или год
-- За прошлую неделю
SELECT * 
FROM invoices 
WHERE manager_id = :manager_id 
AND issue_date >= NOW() - INTERVAL '1 week';

-- За прошлый месяц
SELECT * 
FROM invoices 
WHERE manager_id = :manager_id 
AND issue_date >= NOW() - INTERVAL '1 month';

-- За прошлый год
SELECT * 
FROM invoices 
WHERE manager_id = :manager_id 
AND issue_date >= NOW() - INTERVAL '1 year';


-- Поиск счетов по контрагенту
SELECT * 
FROM invoices 
WHERE contractor_id = :contractor_id -- Замените :contractor_id на нужный ID контрагента
ORDER BY issue_date DESC;


-- Поиск счета по номеру
SELECT * 
FROM invoices 
WHERE invoice_number = :invoice_number -- Замените :invoice_number на нужный номер счета
ORDER BY issue_date DESC;


-- Открытие счета и ознакомление с содержимым
SELECT i.invoice_id
	, i.invoice_number
	, i.issue_date
	, i.total_amount
	, i.status
	, c.name AS contractor_name
	, ii.product_name
	, ii.quantity
	, ii.unit_price
	, ii.total_price
FROM invoices i
JOIN contractors c ON i.contractor_id = c.contractor_id
JOIN invoice_items ii ON i.invoice_id = ii.invoice_id
WHERE i.invoice_id = :invoice_id; -- Замените :invoice_id на нужный ID счета


-- Выборка оплаченных, но не отгруженных счетов
SELECT * 
FROM invoices 
WHERE payment_status = 'Полная' 
  AND shipment_status = 'Не отгружено';


-- Выборка отгруженных, но не оплаченных счетов
SELECT * 
FROM invoices 
WHERE payment_status = 'Не оплачена' 
  AND shipment_status = 'Отгружено';


-- Выбираем счета, которые либо не синхронизировались ранее, либо требуют обновления.
SELECT * 
FROM invoices 
WHERE last_synced IS NULL 
   OR last_synced < NOW() - INTERVAL '1 hour';