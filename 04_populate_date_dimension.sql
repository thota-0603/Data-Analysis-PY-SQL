-- =============================================
-- Populate Date Dimension Table
-- =============================================

USE Orders;
GO

-- Clear existing data
TRUNCATE TABLE dbo.dim_date;
GO

-- Populate date dimension for date range in orders table
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

-- Get min and max dates from orders table
SELECT @StartDate = MIN(order_date), @EndDate = MAX(order_date)
FROM dbo.orders_
WHERE order_date IS NOT NULL;

-- If no dates found, use default range
IF @StartDate IS NULL
BEGIN
    SET @StartDate = '2020-01-01';
    SET @EndDate = '2025-12-31';
END

-- Extend range by 1 year on each side for future use
SET @StartDate = DATEADD(YEAR, -1, @StartDate);
SET @EndDate = DATEADD(YEAR, 1, @EndDate);

PRINT 'Populating date dimension from ' + CAST(@StartDate AS VARCHAR) + ' to ' + CAST(@EndDate AS VARCHAR);

-- Populate date dimension
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO dbo.dim_date (
        date_key,
        date_value,
        year,
        quarter,
        month,
        month_name,
        week,
        day_of_month,
        day_of_week,
        day_name,
        is_weekend,
        fiscal_year,
        fiscal_quarter
    )
    VALUES (
        CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT), -- date_key as yyyyMMdd
        @CurrentDate,                                  -- date_value
        YEAR(@CurrentDate),                            -- year
        DATEPART(QUARTER, @CurrentDate),               -- quarter
        MONTH(@CurrentDate),                           -- month
        DATENAME(MONTH, @CurrentDate),                 -- month_name
        DATEPART(WEEK, @CurrentDate),                  -- week
        DAY(@CurrentDate),                             -- day_of_month
        DATEPART(WEEKDAY, @CurrentDate),               -- day_of_week
        DATENAME(WEEKDAY, @CurrentDate),               -- day_name
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END, -- is_weekend (assuming Sunday=1, Saturday=7)
        YEAR(@CurrentDate),                            -- fiscal_year (same as calendar year, adjust if needed)
        DATEPART(QUARTER, @CurrentDate)               -- fiscal_quarter (same as calendar quarter, adjust if needed)
    );
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END

PRINT 'Date dimension populated successfully!';
GO

-- Verify
SELECT COUNT(*) AS total_dates, MIN(date_value) AS min_date, MAX(date_value) AS max_date
FROM dbo.dim_date;
GO
