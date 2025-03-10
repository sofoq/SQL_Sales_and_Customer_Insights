-- This SQL script analyzes customer spending, order patterns, product revenue, discount impact, 
-- sales rep performance, and customer retention.
-- It uses the AdventureWorks2019 database.

--Orders View: Aggregated Sales Data
--drop view if exists Orders
DROP VIEW IF EXISTS Orders;
GO

--1. Create View to aggregate sales data per month, customer, and order ID.
CREATE VIEW Orders AS(
SELECT 
    CAST(DATETRUNC(month, soh.OrderDate) AS DATE) AS OrderMonth,  
    soh.SalesOrderID,
    c.CustomerID,
    CAST(SUM(od.LineTotal) AS DECIMAL(18,2)) AS TotalAmount,  
    SUM(od.OrderQty) AS TotalQty,
    COUNT(soh.SalesOrderID) AS TotalOrders 
FROM [Sales].[SalesOrderHeader] soh
LEFT JOIN [Sales].[SalesOrderDetail] od ON soh.SalesOrderID = od.SalesOrderID
LEFT JOIN [Sales].[Customer] c ON soh.CustomerID = c.CustomerID
LEFT JOIN Production.Product p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, CAST(DATETRUNC(month, soh.OrderDate) AS DATE) , soh.SalesOrderID
)

GO



-- 2. Calculate total spending and total number of orders for each customer, then rank customers by total spending.
SELECT 
    o.OrderMonth,
    o.CustomerID,
    SUM(o.TotalAmount) AS TotalAmount,
    COUNT(o.SalesOrderID) AS TotalOrders,
    DENSE_RANK() OVER (PARTITION BY o.OrderMonth ORDER BY SUM(o.TotalAmount) DESC) AS CustomerRankBySpending
FROM Orders o
GROUP BY o.OrderMonth, o.CustomerID
ORDER BY o.OrderMonth, CustomerRankBySpending;


-- 3. Analyze order patterns by calculating the number of orders placed each month 
--    and comparing it with the previous month.
WITH OrderPatterns AS (
    SELECT 
        o.OrderMonth AS OrderDate,
        COUNT(o.SalesOrderID) AS OrdersPerMonth
    FROM Orders o
    GROUP BY o.OrderMonth
)
SELECT 
    OrderDate,
    OrdersPerMonth,
    LAG(OrdersPerMonth) OVER (ORDER BY OrderDate) AS LastMonthOrders,
    format((OrdersPerMonth - LAG(OrdersPerMonth, 1) OVER (ORDER BY OrderDate)) *100
    / NULLIF(CAST(LAG(OrdersPerMonth, 1) OVER (ORDER BY OrderDate) AS Float), 0),'N2' ) + '%' AS ChangeInOrders

FROM OrderPatterns
ORDER BY OrderDate;


-- 4. Calculate the total revenue for each product, and rank products by total revenue.
WITH ProductRevenue AS (
    SELECT 
        p.ProductID,
        o.OrderMonth AS OrderDate,
        p.Name AS ProductName,
        SUM(o.TotalAmount) AS TotalRevenue
    FROM Orders o
    JOIN [Sales].[SalesOrderDetail] od ON o.SalesOrderID = od.SalesOrderID
    JOIN [Production].[Product] p ON od.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Name, o.OrderMonth
)
SELECT 
    OrderDate,
    ProductID,
    ProductName,
    TotalRevenue,
    DENSE_RANK() OVER (PARTITION BY OrderDate ORDER BY TotalRevenue DESC) AS ProductRank
FROM ProductRevenue
ORDER BY OrderDate, ProductRank;

-- 5. Calculate the average order value (AOV) for each customer and rank customers by AOV.
SELECT 
    o.OrderMonth,
    o.CustomerID,
    CAST(SUM(o.TotalAmount) / COUNT(o.SalesOrderID) as decimal(18,2)) AS AOV,
    DENSE_RANK() OVER (PARTITION BY o.OrderMonth ORDER BY SUM(o.TotalAmount) / COUNT(o.SalesOrderID) DESC) AS CustomerRankByAOV
FROM Orders o
GROUP BY o.OrderMonth, o.CustomerID
ORDER BY o.OrderMonth, AOV DESC;

-- 6. Analyze the impact of discounts on total sales and revenue.
WITH Discount AS (
    SELECT 
        o.OrderMonth,
        o.SalesOrderID,
        SUM(o.TotalQty) AS TotalQty,
        SUM(o.TotalAmount) AS TotalAmount,
        CASE 
            WHEN od.SpecialOfferID = 1 THEN 'Non-Discounted'
            ELSE 'Discounted'
        END AS DiscountStatus,
        -- Calculate DiscountedAmount as TotalAmount * DiscountPct
        CASE 
            WHEN od.SpecialOfferID = 1 THEN 0
            ELSE COALESCE(SUM(o.TotalAmount) * so.DiscountPct, 0)
        END AS DiscountedAmount
    FROM Orders o
    JOIN [Sales].[SalesOrderDetail] od ON o.SalesOrderID = od.SalesOrderID
    LEFT JOIN [Sales].[SpecialOffer] so ON od.SpecialOfferID = so.SpecialOfferID
    GROUP BY o.OrderMonth, o.SalesOrderID, od.SpecialOfferID, so.DiscountPct
)
SELECT 
    OrderMonth,
    SalesOrderID,
    DiscountStatus,
    SUM(TotalQty) AS TotalQty,
    SUM(TotalAmount) AS TotalAmount,
    CAST(SUM(DiscountedAmount) as decimal(18,2)) AS TotalDiscountedAmount
FROM Discount
GROUP BY OrderMonth, DiscountStatus, SalesOrderID
ORDER BY OrderMonth, DiscountStatus;

-- 7. Evaluate sales rep performance by calculating total sales and commission earned, and ranking sales reps by total sales.
SELECT 
    o.OrderMonth,
    sr.BusinessEntityID,
    SUM(o.TotalAmount) AS TotalSales,
    CAST(SUM(o.TotalAmount * sr.CommissionPct) as decimal(18,2))AS CommissionEarned,
    DENSE_RANK() OVER (PARTITION BY o.OrderMonth ORDER BY SUM(o.TotalAmount) DESC) AS SalesRepRank
FROM Orders o
JOIN [Sales].[SalesOrderHeader] soh ON o.SalesOrderID = soh.SalesOrderID
JOIN [Sales].[SalesPerson] sr ON soh.SalesPersonID = sr.BusinessEntityID
GROUP BY o.OrderMonth, sr.BusinessEntityID
ORDER BY o.OrderMonth, SalesRepRank;

-- 8. Analyze customer retention by calculating the number of repeat purchases, average days between purchases, and customer status.
WITH CustomerRetention AS (
    SELECT 
        o.CustomerID,
        o.OrderMonth AS OrderDate,
        LAG(o.OrderMonth) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderMonth) AS PreviousPurchaseDate,
        DATEDIFF(DAY, LAG(o.OrderMonth) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderMonth), o.OrderMonth) AS DaysBetweenPurchases
    FROM Orders o
)
SELECT 
    CustomerID,
    MAX(OrderDate) AS LastPurchaseDate,
    COUNT(OrderDate) AS RepeatPurchases,
    AVG(DaysBetweenPurchases) AS AvgDaysBetweenPurchases,
    CASE 
        WHEN DATEDIFF(DAY, MAX(OrderDate), '2015-01-01') > 365 THEN 'Churned'
        ELSE 'Active'
    END AS CustomerStatus
FROM CustomerRetention
GROUP BY CustomerID;
