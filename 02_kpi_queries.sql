-- =============================================
-- KPI Queries for Orders Analytics
-- =============================================

USE Orders;
GO

-- =============================================
-- 1. Total Revenue
-- =============================================
SELECT 
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity
FROM dbo.orders_;
GO

-- =============================================
-- 2. Top 10 Products by Revenue
-- =============================================
SELECT TOP 10
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
GO

-- =============================================
-- 3. Regional Performance
-- =============================================
SELECT 
    region,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(sale_price * quantity), 2) AS avg_order_value
FROM dbo.orders_
GROUP BY region
ORDER BY total_revenue DESC;
GO

-- =============================================
-- 4. Revenue and Profit by Segment
-- =============================================
SELECT 
    segment,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
FROM dbo.orders_
GROUP BY segment
ORDER BY total_revenue DESC;
GO

-- =============================================
-- 5. Revenue and Profit by Category
-- =============================================
SELECT 
    category,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
FROM dbo.orders_
GROUP BY category
ORDER BY total_revenue DESC;
GO

-- =============================================
-- 6. Monthly Sales Trend
-- =============================================
SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    DATENAME(MONTH, order_date) AS month_name,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity
FROM dbo.orders_
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY order_year, order_month;
GO

-- =============================================
-- 7. Top 10 Products by Profit
-- =============================================
SELECT TOP 10
    product_id,
    sub_category,
    category,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
FROM dbo.orders_
GROUP BY product_id, sub_category, category
ORDER BY total_profit DESC;
GO
