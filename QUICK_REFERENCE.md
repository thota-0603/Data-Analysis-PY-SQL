# Quick Reference Guide

## Common SQL Queries

### Basic KPIs
```sql
-- Total Revenue
SELECT SUM(sale_price * quantity) AS total_revenue FROM dbo.orders_;

-- Total Profit
SELECT SUM(profit) AS total_profit FROM dbo.orders_;

-- Orders Count
SELECT COUNT(DISTINCT order_id) AS total_orders FROM dbo.orders_;
```

### Top Products
```sql
-- Top 10 by Revenue
EXEC sp_TopProductsByRevenue @TopN = 10;

-- Top 10 by Profit
SELECT TOP 10
    product_id, category, sub_category,
    SUM(sale_price * quantity) AS revenue,
    SUM(profit) AS profit
FROM dbo.orders_
GROUP BY product_id, category, sub_category
ORDER BY profit DESC;
```

### Regional Analysis
```sql
-- Revenue by Region
EXEC sp_RevenueByDimension @Dimension = 'REGION';

-- Top States
SELECT TOP 10
    state, region,
    SUM(sale_price * quantity) AS revenue,
    SUM(profit) AS profit
FROM dbo.orders_
GROUP BY state, region
ORDER BY revenue DESC;
```

### Time Analysis
```sql
-- Monthly Trend
EXEC sp_MonthlySalesTrend @StartYear = 2022, @EndYear = 2023;

-- Year-over-Year
SELECT 
    YEAR(order_date) AS year,
    SUM(sale_price * quantity) AS revenue
FROM dbo.orders_
GROUP BY YEAR(order_date)
ORDER BY year;
```

## Python Quick Commands

### Basic Data Load
```python
from data_ingestion import OrdersDataIngestion

ingestion = OrdersDataIngestion()
df = ingestion.read_data('orders.csv')
df_clean = ingestion.clean_and_transform(df)
ingestion.load_to_sql(df_clean, if_exists='append')
ingestion.close_connections()
```

### Update Discounts
```python
ingestion.update_discounts_by_region({
    'South': 0.5,
    'West': -1.0
})
```

### Run Stored Procedure
```python
results = ingestion.run_stored_procedure(
    'sp_TopProductsByRevenue',
    {'TopN': 10}
)
```

## Power BI DAX Quick Reference

### Basic Measures
```dax
Total Sales = SUM(orders_[sale_price]) * SUM(orders_[quantity])
Total Profit = SUM(orders_[profit])
Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0) * 100
```

### Time Intelligence
```dax
Sales YTD = TOTALYTD([Total Sales], dim_date[date_value])
Sales LY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(dim_date[date_value]))
Sales YoY Growth % = DIVIDE([Total Sales] - [Sales LY], [Sales LY], 0) * 100
```

### Filtered Measures
```dax
Sales by Segment = 
CALCULATE(
    [Total Sales],
    VALUES(orders_[segment])
)
```

## File Locations

- **SQL Scripts:** `01_database_setup.sql`, `02_kpi_queries.sql`, `03_analytical_queries.sql`
- **Python Script:** `data_ingestion.py`
- **Power BI Measures:** `PowerBI_DAX_Measures.txt`
- **Dashboard Spec:** `PowerBI_Dashboard_Specification.md`

## Common Issues

| Issue | Solution |
|-------|----------|
| SQL connection fails | Check server name, credentials, SQL Server running |
| Python import error | Run `pip install -r requirements.txt` |
| Power BI no data | Verify tables exist, check relationship |
| Data type error | Check CSV format matches expected structure |

## Next Steps Checklist

- [ ] Run database setup scripts
- [ ] Install Python dependencies
- [ ] Load data using Python script
- [ ] Connect Power BI to SQL Server
- [ ] Create date dimension relationship
- [ ] Add DAX measures
- [ ] Build dashboard pages
- [ ] Schedule data refresh

---

**For detailed instructions, see:** `README.md` and `setup_guide.md`
