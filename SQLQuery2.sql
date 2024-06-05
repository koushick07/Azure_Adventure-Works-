--Create a procedure InsertOrderDetails that takes OrderlD, ProductID, UnitPrice, Quantiy, Discount as input parameters and inserts that order information in the Order Details table. After each order inserted, check the @@rowcount value to make sure that order was inserted properly. If for any reason the order was not inserted, print the message: Failed to place the order. Please try again. Also your procedure should have these functionalities
--Make the UnitPrice and Discount parameters optional
--If no UnitPrice is given, then use the UnitPrice value from the product table.
--If no Discount is given, then use a discount of 0.
--Adjust the quantity in stock (UnitsInStock) for the product by subtracting the quantity sold from inventory.
--However, if there is not enough of a product in stock, then abort the stored procedure without making any changes to the database.
--Print a message if the quantity in stock of a product drops below its Reorder Level as a result of the update.

CREATE PROCEDURE InsertOrderDetails
    @OrderID int,
    @ProductID int,
    @UnitPrice decimal(10,2) = NULL,
    @Quantity int,
    @Discount decimal(10,2) = NULL
AS
BEGIN
    IF @UnitPrice IS NULL
        SET @UnitPrice = (SELECT UnitPrice FROM Products WHERE ProductID = @ProductID)
    ELSE
        SET @UnitPrice = @UnitPrice

    IF @Discount IS NULL
        SET @Discount = 0
    ELSE
        SET @Discount = @Discount

    BEGIN TRANSACTION
    BEGIN TRY
        INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
        VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount)

        IF @@ROWCOUNT = 0
            RAISERROR('Failed to place the order. Please try again.', 16, 1)

        UPDATE Products
        SET UnitsInStock = UnitsInStock - @Quantity
        WHERE ProductID = @ProductID

        IF (SELECT UnitsInStock FROM Products WHERE ProductID = @ProductID) < (SELECT ReorderLevel FROM Products WHERE ProductID = @ProductID)
            PRINT 'Quantity in stock of the product has dropped below its Reorder Level.'

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RAISERROR('Failed to place the order. Please try again.', 16, 1)
    END CATCH
END


--Create a procedure UpdateOrderDetails that takes OrderlD, ProductID, UnitPrice, Quantity, and discount, and updates these values for that ProductID in that Order.
--All the parameters except the OrderlD and ProductID should be optional so that if the user wants to only update Quantity s/he should be able to do so without providing the rest of the values. You need to also make sure that if any of the values are being passed in as NULL, then you want to retain the original value instead of overwriting it with NULL. To accomplish this, look for the ISNULL function in google or sql server books online. Adjust the UnitsInStock value in products table accordingly.

CREATE PROCEDURE UpdateOrderDetails
    @OrderID int,
    @ProductID int,
    @UnitPrice decimal(10,2) = NULL,
    @Quantity int = NULL,
    @Discount decimal(10,2) = NULL
AS
BEGIN
    DECLARE @OriginalUnitPrice decimal(10,2)
    DECLARE @OriginalQuantity int
    DECLARE @OriginalDiscount decimal(10,2)

    SELECT @OriginalUnitPrice = ISNULL(UnitPrice, @UnitPrice),
           @OriginalQuantity = ISNULL(Quantity, @Quantity),
           @OriginalDiscount = ISNULL(Discount, @Discount)
    FROM OrderDetails
    WHERE OrderID = @OrderID AND ProductID = @ProductID

    BEGIN TRANSACTION
    BEGIN TRY
        UPDATE OrderDetails
        SET UnitPrice = @OriginalUnitPrice,
            Quantity = @OriginalQuantity,
            Discount = @OriginalDiscount
        WHERE OrderID = @OrderID AND ProductID = @ProductID

        UPDATE Products
        SET UnitsInStock = UnitsInStock + @OriginalQuantity - ISNULL(@Quantity, @OriginalQuantity)
        WHERE ProductID = @ProductID

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RAISERROR('Failed to update order details. Please try again.', 16, 1)
    END CATCH
END


--Create a procedure GetOrderDetails that takes OrderlD as input parameter and returns all the records for that OrderID. If no records are found in Order Details table, then it should print the line: "The OrderID XXXX does not exits" , where XXX should be the OrderlD entered by user and the procedure should RETURN the value 1.


CREATE PROCEDURE GetOrderDetails
    @OrderID int
AS
BEGIN
    SELECT * FROM OrderDetails
    WHERE OrderID = @OrderID

    IF @@ROWCOUNT = 0
        PRINT 'The OrderID ' + CONVERT(varchar(5), @OrderID) + ' does not exist'
    RETURN 1
END
--Create a procedure DeleteOrderDetails that takes OrderID and ProductID and deletes that from Order Details table. Your procedure should validate parameters.
--It should return an error code (-1) and print a message if the parameters are invalid. Parameters are valid if the given order ID appears in the table and if the given product TD appears in that order.

CREATE PROCEDURE DeleteOrderDetails
    @OrderID int,
    @ProductID int
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
    BEGIN
        PRINT 'Invalid OrderID. The order does not exist.'
        RETURN -1
    END

    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Invalid ProductID. The product is not part of the order.'
        RETURN -1
    END

    BEGIN TRANSACTION
    BEGIN TRY
        DELETE FROM OrderDetails
        WHERE OrderID = @OrderID AND ProductID = @ProductID

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RAISERROR('Failed to delete order details. Please try again.', 16, 1)
    END CATCH
END

-- Functions
-----------------

-- Review SQL Server date formats on this website and then create following functions

-- http://www.sql-server-helper.com/tips/date-formats.aspx

-- Create a function that takes an input parameter type datetime and returns the date in the format MM/DD/YYYY. For example if I pass in 2006-11-21 23:34:05.920', the output of the
--  functions should be 11/21/2006


CREATE FUNCTION FormatDate_MMDDYYYY (@datetime datetime)
RETURNS varchar(10)
AS
BEGIN
    RETURN CONVERT(varchar(10), CONVERT(date, @datetime), 101)
END



-- Create a function that takes an input parameter type datetime and returns the date in the fonnat YYYYMMDD



CREATE FUNCTION FormatDate_YYYYMMDD (@datetime datetime)
RETURNS varchar(10)
AS
BEGIN
    RETURN CONVERT(varchar(10), CONVERT(date, @datetime), 112)
END


-- Views
------------------

-- Create a view vwCustomerOrders which returns CompanyName OrderID.OrderDate, ProductID ProductName Quantity UnitPrice.Quantity od. UnitPrice


CREATE VIEW vwCustomerOrders AS
SELECT c.CompanyName, od.OrderID, od.OrderDate, p.ProductName, od.Quantity, od.UnitPrice
FROM Sales.OrderDetails od INNER JOIN Products p ON od.ProductID = p.ProductID INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID INNER JOIN Customers c ON o.CustomerID = c.CustomerID



-- Create a copy of the above view and modify it so that it only returns the above information for orders that were placed yesterday


CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT c.CompanyName, od.OrderID, od.OrderDate, p.ProductName, od.Quantity, od.UnitPrice
FROM Sales.OrderDetails od INNER JOIN Products p ON od.ProductID = p.ProductID INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE CAST(od.OrderDate AS date) = CAST(GETDATE() - 1 AS date)


-- Use a CREATE VIEW statement to create a view called MyProducts. Your view should contain the ProductID, ProductName, QuantityPerUnit and Unit Price columns from the Products table. It
-- should also contain the CompanyName column from the Suppliers table and the CategoryName column from the Categories table. Your view should only contain products that are 
-- not discontinued. 


CREATE VIEW MyProducts AS
SELECT p.ProductID, p.ProductName, p.QuantityPerUnit, p.UnitPrice, s.CompanyName, c.CategoryName
FROM Products p LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID LEFT JOIN Categories c ON p.CategoryID = c.CategoryID WHERE p.DiscontinuedDate IS NULL;




-- Triggers
-------------------

-- If someone cancels an order in northwind database, then you want to delete that order from the Orders table. But you will not be able to delete that Order before deleting the records 
-- from Order Details table for that particular order due to referential integrity constraints. Create an Instead of Delete trigger on Orders table so that if some one tries to delete an
-- Order that trigger gets fired and that trigger should first delete everything in order details table and then delete that order from the Orders table


CREATE TRIGGER trg_DeleteOrdersInsteadOfDelete ON Orders INSTEAD OF DELETE AS
BEGIN
    DELETE FROM Sales.OrderDetails WHERE OrderID IN (SELECT OrderID FROM deleted)
    DELETE FROM Orders WHERE OrderId IN (SELECT OrderId FROM deleted)
END



-- When an order is placed for X units of product Y, we must first check the Products table to ensure that there is sufficient stock to fill the order. This trigger will operate on the
-- Order Details table. If sufficient stock exists, then fill the order and decrement X units from the UnitsInStock column in Products. If insufficient stock exists, then refuse the order
-- (le. do not insert it) and notify the user that the order could not be filled because of insufficient stock.
 


CREATE TRIGGER trg_CheckInventory BEFORE INSERT ON Sales.OrderDetails AS
BEGIN
    IF EXISTS (SELECT 1 FROM Production.Product WHERE ProductId = INSERTED.ProductId AND UnitsInStock < INSERTED.Quantity)
        ROLLBACK TRANSACTION;
END;