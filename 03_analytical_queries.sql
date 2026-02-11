-- =============================================
-- Analytical SQL Queries and Stored Procedures
-- =============================================

USE Orders;
GO

-- =============================================
-- Stored Procedure: Top N Products by Revenue
-- =============================================
IF OBJECT_ID('sp_TopProductsByRevenue', 'P') IS NOT NULL
    DROP PROCEDURE sp_TopProductsByRevenue;
GO

CREATE PROCEDURE sp_TopProductsByRevenue
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopN)
        product_id,
        sub_category,
        category,
        SUM(sale_price * quantity) AS total_revenue,
        SUM(profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
    FROM dbo.orders_
    GROUP BY product_id, sub_category, category
    ORDER BY total_revenue DESC;
END
GO

-- =============================================
-- Stored Procedure: Revenue and Profit by Segment, Category, Region
-- =============================================
IF OBJECT_ID('sp_RevenueByDimension', 'P') IS NOT NULL
    DROP PROCEDURE sp_RevenueByDimension;
GO

CREATE PROCEDURE sp_RevenueByDimension
    @Dimension VARCHAR(20) = 'SEGMENT' -- SEGMENT, CATEGORY, or REGION
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Dimension = 'SEGMENT'
    BEGIN
        SELECT 
            segment AS dimension_value,
            COUNT(DISTINCT order_id) AS order_count,
            SUM(sale_price * quantity) AS total_revenue,
            SUM(profit) AS total_profit,
            ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
        FROM dbo.orders_
        GROUP BY segment
        ORDER BY total_revenue DESC;
    END
    ELSE IF @Dimension = 'CATEGORY'
    BEGIN
        SELECT 
            category AS dimension_value,
            COUNT(DISTINCT order_id) AS order_count,
            SUM(sale_price * quantity) AS total_revenue,
            SUM(profit) AS total_profit,
            ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
        FROM dbo.orders_
        GROUP BY category
        ORDER BY total_revenue DESC;
    END
    ELSE IF @Dimension = 'REGION'
    BEGIN
        SELECT 
            region AS dimension_value,
            COUNT(DISTINCT order_id) AS order_count,
            SUM(sale_price * quantity) AS total_revenue,
            SUM(profit) AS total_profit,
            ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
        FROM dbo.orders_
        GROUP BY region
        ORDER BY total_revenue DESC;
    END
END
GO

-- =============================================
-- Stored Procedure: Monthly Sales Trend
-- =============================================
IF OBJECT_ID('sp_MonthlySalesTrend', 'P') IS NOT NULL
    DROP PROCEDURE sp_MonthlySalesTrend;
GO

CREATE PROCEDURE sp_MonthlySalesTrend
    @StartYear INT = NULL,
    @EndYear INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        DATENAME(MONTH, order_date) AS month_name,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(sale_price * quantity) AS total_revenue,
        SUM(profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(sale_price * quantity), 2) AS avg_order_value
    FROM dbo.orders_
    WHERE order_date IS NOT NULL
        AND (@StartYear IS NULL OR YEAR(order_date) >= @StartYear)
        AND (@EndYear IS NULL OR YEAR(order_date) <= @EndYear)
    GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
    ORDER BY order_year, order_month;
END
GO

-- =============================================
-- T-SQL Cursor Example: Process Orders and Update Summary Table
-- =============================================

-- Create summary/audit table
IF OBJECT_ID('dbo.order_summary', 'U') IS NOT NULL
    DROP TABLE dbo.order_summary;
GO

CREATE TABLE dbo.order_summary (
    summary_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    order_date DATE NULL,
    total_revenue DECIMAL(10,2) NULL,
    total_profit DECIMAL(10,2) NULL,
    total_quantity INT NULL,
    avg_discount DECIMAL(5,2) NULL,
    processed_date DATETIME DEFAULT GETDATE()
);
GO

-- Stored Procedure with Cursor to Process Orders
IF OBJECT_ID('sp_ProcessOrdersWithCursor', 'P') IS NOT NULL
    DROP PROCEDURE sp_ProcessOrdersWithCursor;
GO

CREATE PROCEDURE sp_ProcessOrdersWithCursor
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @order_id INT;
    DECLARE @order_date DATE;
    DECLARE @total_revenue DECIMAL(10,2);
    DECLARE @total_profit DECIMAL(10,2);
    DECLARE @total_quantity INT;
    DECLARE @avg_discount DECIMAL(5,2);
    
    -- Declare cursor
    DECLARE order_cursor CURSOR FOR
        SELECT DISTINCT order_id, order_date
        FROM dbo.orders_
        WHERE order_id NOT IN (SELECT order_id FROM dbo.order_summary)
        ORDER BY order_id;
    
    OPEN order_cursor;
    FETCH NEXT FROM order_cursor INTO @order_id, @order_date;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calculate aggregates for this order
        SELECT 
            @total_revenue = SUM(sale_price * quantity),
            @total_profit = SUM(profit),
            @total_quantity = SUM(quantity),
            @avg_discount = AVG(discount)
        FROM dbo.orders_
        WHERE order_id = @order_id;
        
        -- Insert into summary table
        INSERT INTO dbo.order_summary (order_id, order_date, total_revenue, total_profit, total_quantity, avg_discount)
        VALUES (@order_id, @order_date, @total_revenue, @total_profit, @total_quantity, @avg_discount);
        
        FETCH NEXT FROM order_cursor INTO @order_id, @order_date;
    END
    
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
    
    PRINT 'Orders processed successfully!';
END
GO

-- =============================================
-- Query: Revenue and Profit by Sub-Category
-- =============================================
SELECT 
    category,
    sub_category,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct,
    SUM(quantity) AS total_quantity
FROM dbo.orders_
GROUP BY category, sub_category
ORDER BY category, total_revenue DESC;
GO

-- =============================================
-- Query: Discount Impact Analysis
-- =============================================
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 10 THEN 'Low Discount (1-10%)'
        WHEN discount > 10 AND discount <= 20 THEN 'Medium Discount (11-20%)'
        WHEN discount > 20 AND discount <= 30 THEN 'High Discount (21-30%)'
        ELSE 'Very High Discount (>30%)'
    END AS discount_range,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct,
    AVG(discount) AS avg_discount_pct
FROM dbo.orders_
GROUP BY 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 10 THEN 'Low Discount (1-10%)'
        WHEN discount > 10 AND discount <= 20 THEN 'Medium Discount (11-20%)'
        WHEN discount > 20 AND discount <= 30 THEN 'High Discount (21-30%)'
        ELSE 'Very High Discount (>30%)'
    END
ORDER BY 
    CASE 
        WHEN discount = 0 THEN 1
        WHEN discount > 0 AND discount <= 10 THEN 2
        WHEN discount > 10 AND discount <= 20 THEN 3
        WHEN discount > 20 AND discount <= 30 THEN 4
        ELSE 5
    END;
GO

PRINT 'Analytical queries and stored procedures created successfully!';
GO
