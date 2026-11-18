
  -- PROJECT : AdventureWorks SQL Project - JOINs and Subqueries
  -- DATABASE: AdventureWorks2019 
  -- AUTHOR  : <ADIGUN KARIMOT>
  -- DATE    : <18/8/2026>

USE AdventureWorks2019
JOIN QUESTIONS

-- Q1: What are the top 10 best-selling products by total quantity sold?
-- Concepts: INNER JOIN, GROUP BY, SUM, LIMIT
SELECT p.ProductID,p.Name AS ProductName,
    SUM(sod.OrderQty)   AS TotalQuantitySold
FROM Sales_SalesOrderDetail AS sod
INNER JOIN Production_Product AS p
ON sod.ProductID = p.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalQuantitySold DESC
LIMIT 10;


-- Q2: Which product categories generate the most revenue?
-- Concepts: 3 INNER JOINs chained through the product hierarchy
SELECT pc.Name AS Category,
ROUND(SUM(sod.LineTotal), 2)  AS TotalRevenue
FROM Sales_SalesOrderDetail AS sod
INNER JOIN Production_Product AS p
ON sod.ProductID = p.ProductID
INNER JOIN Production_ProductSubcategory AS psc
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production_ProductCategory AS pc
ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;


-- Q3: Which sales territories have the highest total sales?
-- Concepts: INNER JOIN, GROUP BY, SUM)
SELECT st.Name AS Territory, st.CountryRegionCode,
st.`Group` AS SalesGroup,
ROUND(SUM(soh.TotalDue), 2) AS TotalSales
FROM Sales_SalesOrderHeader AS soh
INNER JOIN Sales_SalesTerritory AS st
ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name, st.CountryRegionCode, st.`Group`
ORDER BY TotalSales DESC;


-- Q4: Who are the top 10 individual customers by total amount spent?
-- Concepts: 3-table INNER JOIN (Order -> Customer -> Person)
SELECT c.CustomerID,
CONCAT(pe.FirstName, ' ', pe.LastName) AS CustomerName,
COUNT(soh.SalesOrderID) AS NumberOfOrders,
ROUND(SUM(soh.TotalDue), 2) AS TotalSpent
FROM Sales_SalesOrderHeader AS soh
INNER JOIN Sales_Customer AS c
ON soh.CustomerID = c.CustomerID
INNER JOIN Person_Person AS pe
ON c.PersonID = pe.BusinessEntityID
GROUP BY c.CustomerID, pe.FirstName, pe.LastName
ORDER BY TotalSpent DESC
LIMIT 10;


-- Q5: How much has each salesperson sold, and which territory are they assigned to?
-- Concepts: INNER JOINs plus a LEFT JOIN 
SELECT sp.BusinessEntityID AS SalesPersonID,
CONCAT(pe.FirstName, ' ', pe.LastName) AS SalesPerson,
st.Name AS Territory,
COUNT(soh.SalesOrderID) AS NumberOfOrders,
ROUND(SUM(soh.TotalDue), 2) AS TotalSales
FROM Sales_SalesPerson AS sp
INNER JOIN Person_Person AS pe
ON sp.BusinessEntityID = pe.BusinessEntityID
INNER JOIN Sales_SalesOrderHeader AS soh
ON sp.BusinessEntityID = soh.SalesPersonID
LEFT JOIN Sales_SalesTerritory AS st
ON sp.TerritoryID = st.TerritoryID
GROUP BY sp.BusinessEntityID, pe.FirstName, pe.LastName, st.Name
ORDER BY TotalSales DESC;


-- Q6: Which products have never been sold?

SELECT p.ProductID, p.Name AS ProductName, p.ListPrice
FROM Production_Product AS p
LEFT JOIN Sales_SalesOrderDetail AS sod
ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL
ORDER BY p.Name;


-- Q7: List every current employee with their job title and current department.
-- Concepts: 3 INNER JOINs; 
SELECT CONCAT(pe.FirstName, ' ', pe.LastName) AS EmployeeName, e.JobTitle,
d.Name AS Department
FROM HumanResources_Employee AS e
INNER JOIN Person_Person AS person
ON e.BusinessEntityID = pe.BusinessEntityID
INNER JOIN HumanResources_EmployeeDepartmentHistory AS edh
ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources_Department AS d
ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
ORDER BY d.Name, EmployeeName;


-- Q8: Which vendors supply the most products, and what is their credit rating?
-- Concepts: INNER JOIN, COUNT, GROUP BY
SELECT v.BusinessEntityID AS VendorID,
v.Name AS VendorName, v.CreditRating,
COUNT(pv.ProductID) AS NumberOfProductsSupplied
FROM Purchasing_Vendor AS v
INNER JOIN Purchasing_ProductVendor AS pv
ON v.BusinessEntityID = pv.BusinessEntityID
GROUP BY v.BusinessEntityID, v.Name, v.CreditRating
ORDER BY NumberOfProductsSupplied DESC, VendorName;

--SUBQUERY
-- Q9: Which products have a list price higher than the average list price?
-- Concepts: Scalar subquery in WHERE
SELECT ProductID, Name, ListPrice
FROM Production_Product
WHERE ListPrice > (
SELECT AVG(ListPrice)
FROM Production_Product
WHERE ListPrice > 0)
ORDER BY ListPrice DESC;


-- Q10: Which orders are worth more than the average order value, and who placed them?
-- Concepts: Scalar subquery in WHERE + LEFT JOINs
SELECT soh.SalesOrderID, soh.OrderDate,
COALESCE(CONCAT(pe.FirstName, ' ', pe.LastName), s.Name) AS CustomerName,
soh.TotalDue
FROM Sales_SalesOrderHeader AS soh
INNER JOIN Sales_Customer AS c
ON soh.CustomerID = c.CustomerID
LEFT JOIN Person_Person AS pe
ON c.PersonID = pe.BusinessEntityID
LEFT JOIN Sales_Store AS s
ON c.StoreID = s.BusinessEntityID
WHERE soh.TotalDue > (
SELECT AVG(TotalDue)
FROM Sales_SalesOrderHeader)
ORDER BY soh.TotalDue DESC
LIMIT 50;


-- Q11: Which employees have a current pay rate above the company average?
SELECT
CONCAT(pe.FirstName, ' ', pe.LastName) AS EmployeeName,
e.JobTitle,
eph.Rate AS CurrentRate
FROM HumanResources_EmployeePayHistory AS eph
INNER JOIN Person_Person AS pe
ON eph.BusinessEntityID = pe.BusinessEntityID
INNER JOIN HumanResources_Employee AS e
ON eph.BusinessEntityID = e.BusinessEntityID
WHERE eph.RateChangeDate = (
SELECT MAX(eph2.RateChangeDate)
FROM HumanResources_EmployeePayHistory AS eph2
WHERE eph2.BusinessEntityID = eph.BusinessEntityID)
AND eph.Rate > (
SELECT AVG(Rate)
FROM HumanResources_EmployeePayHistory)
ORDER BY eph.Rate DESC;


-- Q12: Which customers have placed orders but have NEVER bought a product from the "Bikes" category?

SELECT DISTINCT c.CustomerID,
COALESCE(CONCAT(pe.FirstName, ' ', pe.LastName), s.Name) AS CustomerName
FROM Sales_Customer AS c
INNER JOIN Sales_SalesOrderHeader AS soh
ON c.CustomerID = soh.CustomerID
LEFT JOIN Person_Person AS pe
ON c.PersonID = pe.BusinessEntityID
LEFT JOIN Sales_Store AS s
ON c.StoreID = s.BusinessEntityID
WHERE c.CustomerID NOT IN (
SELECT soh2.CustomerID
FROM Sales_SalesOrderHeader AS soh2
INNER JOIN Sales_SalesOrderDetail AS sod
ON soh2.SalesOrderID = sod.SalesOrderID
INNER JOIN Production_Product AS p
ON sod.ProductID = p.ProductID
INNER JOIN Production_ProductSubcategory AS psc
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production_ProductCategory AS pc
ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Bikes'
)
ORDER BY c.CustomerID
LIMIT 100;


-- Q13: Which salespeople have total sales above the average of all salespeople?
-- Concepts: Subquery in FROM (derived table) + nested subquery in WHERE
SELECT
CONCAT(pe.FirstName, ' ', pe.LastName) AS SalesPerson, ps.TotalSales
FROM (
        SELECT SalesPersonID, SUM(TotalDue) AS TotalSales
        FROM Sales_SalesOrderHeader
        WHERE SalesPersonID IS NOT NULL
        GROUP BY SalesPersonID
     ) AS ps
INNER JOIN Person_Person AS pe
        ON ps.SalesPersonID = pe.BusinessEntityID
WHERE ps.TotalSales > (
        SELECT AVG(t.TotalSales)
        FROM (SELECT SUM(TotalDue) AS TotalSales
                FROM Sales_SalesOrderHeader
                WHERE SalesPersonID IS NOT NULL
                GROUP BY SalesPersonID) AS t)
ORDER BY ps.TotalSales DESC;


-- Q14: What is the most expensive product in each product subcategory?

SELECT
    psc.Name AS Subcategory,
    p.Name   AS ProductName,
    p.ListPrice
FROM Production_Product AS p
INNER JOIN Production_ProductSubcategory AS psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE p.ListPrice = (
        SELECT MAX(p2.ListPrice)
        FROM Production_Product AS p2
        WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID)
ORDER BY p.ListPrice DESC;


-- Q15: Which products appear in more orders than the average product does?
-- Concepts: Subquery in HAVING + derived table
SELECT p.ProductID, p.Name AS ProductName,
    COUNT(sod.SalesOrderID)  AS TimesOrdered
FROM Sales_SalesOrderDetail AS sod
INNER JOIN Production_Product AS p
        ON sod.ProductID = p.ProductID
GROUP BY p.ProductID, p.Name
HAVING COUNT(sod.SalesOrderID) > (
        SELECT AVG(t.OrderCount)
        FROM (
                SELECT COUNT(SalesOrderID) AS OrderCount
                FROM Sales_SalesOrderDetail
                GROUP BY ProductID) AS t)
ORDER BY TimesOrdered DESC;
