--SAMPLE DATA

create database CSI2
use CSI2

--create tables

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(50) NOT NULL,
    SupplierID INT NOT NULL,
    CategoryID INT NOT NULL,
    QuantityPerUnit NVARCHAR(20),
    UnitPrice DECIMAL(18, 2),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BIT
);

CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    CompanyName NVARCHAR(50) NOT NULL,
    ContactName NVARCHAR(50),
    ContactTitle NVARCHAR(50),
    Address NVARCHAR(50),
    City NVARCHAR(50),
    Region NVARCHAR(50),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(50),
    Phone NVARCHAR(20)
);

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255)
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CompanyName NVARCHAR(50) NOT NULL,
    ContactName NVARCHAR(50),
    ContactTitle NVARCHAR(50),
    Address NVARCHAR(50),
    City NVARCHAR(50),
    Region NVARCHAR(50),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(50),
    Phone NVARCHAR(20)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME,
    ShippedDate DATETIME,
    ShipVia INT,
    Freight DECIMAL(18, 2),
    ShipName NVARCHAR(50),
    ShipAddress NVARCHAR(50),
    ShipCity NVARCHAR(50),
    ShipRegion NVARCHAR(50),
    ShipPostalCode NVARCHAR(20),
    ShipCountry NVARCHAR(50)
);

CREATE TABLE OrderDetails (
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(18, 2),
    Quantity INT,
    Discount DECIMAL(18, 2),
    PRIMARY KEY (OrderID, ProductID)
);

--inserting datas into the tables

-- Insert Sample Data for Products
INSERT INTO Products (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued)
VALUES 
(1, 'ProductA', 1, 1, '10 boxes', 20.0, 100, 0, 10, 0),
(2, 'ProductB', 2, 1, '20 boxes', 15.0, 50, 0, 5, 0);

-- Insert Sample Data for Suppliers
INSERT INTO Suppliers (SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone)
VALUES 
(1, 'SupplierA', 'John Doe', 'Manager', '123 Street', 'CityA', 'RegionA', '12345', 'CountryA', '123-456-7890'),
(2, 'SupplierB', 'Jane Smith', 'Director', '456 Avenue', 'CityB', 'RegionB', '67890', 'CountryB', '098-765-4321');

-- Insert Sample Data for Categories
INSERT INTO Categories (CategoryID, CategoryName, Description)
VALUES 
(1, 'CategoryA', 'DescriptionA'),
(2, 'CategoryB', 'DescriptionB');

-- Insert Sample Data for Customers
INSERT INTO Customers (CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone)
VALUES 
(1, 'CustomerA', 'Alice Brown', 'Sales Rep', '789 Boulevard', 'CityC', 'RegionC', '11223', 'CountryC', '321-654-9870');

-- Insert Sample Data for Orders
INSERT INTO Orders (OrderID, CustomerID, OrderDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry)
VALUES 
(1, 1, GETDATE(), NULL, 1, 5.0, 'ShipA', '789 Boulevard', 'CityC', 'RegionC', '11223', 'CountryC');

-- Insert Sample Data for OrderDetails
INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES 
(1, 1, 20.0, 5, 0.0),
(1, 2, 15.0, 3, 0.1);








--Stored Procedure

--1) InsertOrderDetails Procedure

CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(18, 2),
    @Quantity INT,
    @Discount DECIMAL(18, 2)
AS
BEGIN
    DECLARE @rowcount INT;
    DECLARE @currentUnitPrice DECIMAL(18, 2);
    DECLARE @currentQuantity INT;

    IF @UnitPrice IS NULL
    BEGIN
        SELECT @currentUnitPrice = UnitPrice FROM Product WHERE ProductID = @ProductID;
        SET @UnitPrice = @currentUnitPrice;
    END

    IF @Discount IS NULL
    BEGIN
        SET @Discount = 0;
    END

    SELECT @currentQuantity = UnitInStock FROM Product WHERE ProductID = @ProductID;

    IF @currentQuantity < @Quantity
    BEGIN
        PRINT 'Not enough stock to fulfill the order';
        RETURN;
    END

    INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
    VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount);

    SET @rowcount = @@ROWCOUNT;

    IF @rowcount = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    UPDATE Product
    SET UnitInStock = UnitInStock - @Quantity
    WHERE ProductID = @ProductID;

    SELECT @currentQuantity = UnitInStock FROM Product WHERE ProductID = @ProductID;

    IF @currentQuantity < ReorderLevel
    BEGIN
        PRINT 'Warning: The quantity in stock has dropped below the Reorder Level.';
    END
END;


--2)UpdateOrderDetails Procedure

CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(18, 2) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(18, 2) = NULL
AS
BEGIN
    DECLARE @currentUnitPrice DECIMAL(18, 2);
    DECLARE @currentQuantity INT;

    IF @UnitPrice IS NOT NULL
    BEGIN
        UPDATE OrderDetails
        SET UnitPrice = @UnitPrice
        WHERE OrderID = @OrderID AND ProductID = @ProductID;
    END

    IF @Quantity IS NOT NULL
    BEGIN
        SELECT @currentQuantity = UnitInStock FROM Product WHERE ProductID = @ProductID;

        IF @currentQuantity < @Quantity
        BEGIN
            PRINT 'Not enough stock to fulfill the order';
            RETURN;
        END

        UPDATE OrderDetails
        SET Quantity = @Quantity
        WHERE OrderID = @OrderID AND ProductID = @ProductID;

        UPDATE Product
        SET UnitInStock = UnitInStock - @Quantity
        WHERE ProductID = @ProductID;
    END

    IF @Discount IS NOT NULL
    BEGIN
        UPDATE OrderDetails
        SET Discount = @Discount
        WHERE OrderID = @OrderID AND ProductID = @ProductID;
    END

    -- Using ISNULL function to retain original value if NULL is passed
    UPDATE OrderDetails
    SET UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        Quantity = ISNULL(@Quantity, Quantity),
        Discount = ISNULL(@Discount, Discount)
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    SELECT @currentQuantity = UnitInStock FROM Product WHERE ProductID = @ProductID;

    IF @currentQuantity < ReorderLevel
    BEGIN
        PRINT 'Warning: The quantity in stock has dropped below the Reorder Level.';
    END
END;


--3)GetOrderDetails Procedure

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN;
    END

    SELECT *
    FROM OrderDetails
    WHERE OrderID = @OrderID;
END;


--4)DeleteOrderDetails Procedure

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Invalid parameters';
        RETURN -1;
    END

    DELETE FROM OrderDetails
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    RETURN 0;
END;


--Functions

--1)Function to return date in MM/DD/YYYY format

CREATE FUNCTION FormatDateMMDDYYYY (@InputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @InputDate, 101);
END;

--2)Function to return date in YYYYMMDD format

CREATE FUNCTION FormatDateYYYYMMDD (@InputDate DATETIME)
RETURNS VARCHAR(8)
AS
BEGIN
    RETURN CONVERT(VARCHAR(8), @InputDate, 112);
END;


--views

--1)View vwCustomerOrders

CREATE VIEW vwCustomerOrders
AS
SELECT 
    c.CompanyName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS TotalPrice
FROM 
    Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Customers c ON o.CustomerID = c.CustomerID;


	--2) View for orders placed yesterday

	CREATE VIEW vwCustomerOrdersYesterday
AS
SELECT 
    c.CompanyName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS TotalPrice
FROM 
    Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE 
    CAST(o.OrderDate AS DATE) = CAST(GETDATE() - 1 AS DATE);


	--3)View MyProducts

	CREATE VIEW MyProducts
AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName,
    c.CategoryName
FROM 
    Products p
    JOIN Suppliers s ON p.SupplierID = s.SupplierID
    JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE 
    p.Discontinued = 0;


	--Triggers

--1)Trigger to delete an order if all items are deleted

	CREATE TRIGGER trgDeleteOrder
ON OrderDetails
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @OrderID INT;

    SELECT @OrderID = OrderID FROM DELETED;

    DELETE FROM OrderDetails WHERE OrderID = @OrderID;

    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)
    BEGIN
        DELETE FROM Orders WHERE OrderID = @OrderID;
    END
END;


--2)Trigger to check stock before placing an order

CREATE TRIGGER trgCheckStockBeforeInsert
ON OrderDetails
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @ProductID INT;
    DECLARE @OrderID INT;
    DECLARE @Quantity INT;
    DECLARE @UnitInStock INT;

    SELECT @ProductID = i.ProductID, @OrderID = i.OrderID, @Quantity = i.Quantity
    FROM INSERTED i;

    SELECT @UnitInStock = UnitInStock FROM Products WHERE ProductID = @ProductID;

    IF @UnitInStock >= @Quantity
    BEGIN
        INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
        SELECT OrderID, ProductID, UnitPrice, Quantity, Discount FROM INSERTED;

        UPDATE Products
        SET UnitInStock = UnitInStock - @Quantity
        WHERE ProductID = @ProductID;
    END
    ELSE
    BEGIN
        PRINT 'Order cannot be fulfilled due to insufficient stock.';
    END
END;




--testing from the sample data


--Executing Stored Procedures

-- Execute InsertOrderDetails Procedure
EXEC InsertOrderDetails @OrderID = 1, @ProductID = 1, @UnitPrice = NULL, @Quantity = 10, @Discount = 0;

-- Execute UpdateOrderDetails Procedure
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1, @Quantity = 7;

-- Execute GetOrderDetails Procedure
EXEC GetOrderDetails @OrderID = 1;

-- Execute DeleteOrderDetails Procedure
EXEC DeleteOrderDetails @OrderID = 1, @ProductID = 2;


--Executing Functions

-- Execute FormatDateMMDDYYYY Function
SELECT dbo.FormatDateMMDDYYYY('2024-06-14 23:34:05.920');

-- Execute FormatDateYYYYMMDD Function
SELECT dbo.FormatDateYYYYMMDD('2024-06-14 23:34:05.920');


--Selecting from Views

-- Select from vwCustomerOrders View
SELECT * FROM vwCustomerOrders;

-- Select from vwCustomerOrdersYesterday View
SELECT * FROM vwCustomerOrdersYesterday;

-- Select from MyProducts View
SELECT * FROM MyProducts;


--Testing Triggers

-- Insert into OrderDetails to Test trgCheckStockBeforeInsert
INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES (1, 1, 20.0, 200, 0.0); -- This should fail due to insufficient stock

-- Delete from OrderDetails to Test trgDeleteOrder
DELETE FROM OrderDetails WHERE OrderID = 1 AND ProductID = 1;
