-- =============================================
-- Orders Analytics Database Setup
-- =============================================

-- Create database (if it doesn't exist)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Orders')
BEGIN
    CREATE DATABASE Orders;
END
GO

USE Orders;
GO

-- Drop table if exists (for clean setup)
IF OBJECT_ID('dbo.orders_', 'U') IS NOT NULL
    DROP TABLE dbo.orders_;
GO

-- Create fact table dbo.orders_
CREATE TABLE dbo.orders_ (
    order_id      INT           NOT NULL PRIMARY KEY,
    order_date    DATE          NULL,
    ship_mode     VARCHAR(50)   NULL,
    segment       VARCHAR(50)   NULL,
    country       VARCHAR(50)   NULL,
    city          VARCHAR(100)  NULL,
    state         VARCHAR(50)   NULL,
    postal_code   VARCHAR(20)   NULL,
    region        VARCHAR(50)   NULL,
    category      VARCHAR(50)   NULL,
    sub_category  VARCHAR(50)   NULL,
    product_id    VARCHAR(50)   NULL,
    quantity      INT           NULL,
    discount      DECIMAL(5,2)  NULL,
    sale_price    DECIMAL(10,2) NULL,
    profit        DECIMAL(10,2) NULL
);
GO

-- Create indexes for better query performance
CREATE INDEX IX_orders_order_date ON dbo.orders_(order_date);
CREATE INDEX IX_orders_region ON dbo.orders_(region);
CREATE INDEX IX_orders_segment ON dbo.orders_(segment);
CREATE INDEX IX_orders_category ON dbo.orders_(category);
CREATE INDEX IX_orders_product_id ON dbo.orders_(product_id);
GO

-- Create Date dimension table for Power BI
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL
    DROP TABLE dbo.dim_date;
GO

CREATE TABLE dbo.dim_date (
    date_key          INT          NOT NULL PRIMARY KEY,
    date_value        DATE         NOT NULL,
    year              INT          NULL,
    quarter           INT          NULL,
    month             INT          NULL,
    month_name        VARCHAR(20)  NULL,
    week              INT          NULL,
    day_of_month      INT          NULL,
    day_of_week       INT          NULL,
    day_name          VARCHAR(20)  NULL,
    is_weekend        BIT          NULL,
    fiscal_year       INT          NULL,
    fiscal_quarter   INT          NULL
);
GO

PRINT 'Database and tables created successfully!';
GO
