# Quick Setup Guide

## Prerequisites Checklist

- [ ] SQL Server installed and running
- [ ] SQL Server Management Studio (SSMS) installed
- [ ] Python 3.8+ installed
- [ ] Power BI Desktop installed
- [ ] ODBC Driver 17 for SQL Server installed

## Step-by-Step Setup

### 1. SQL Server Setup (5 minutes)

```sql
-- Step 1: Run database setup script
-- Open SSMS → File → Open → 01_database_setup.sql → Execute

-- Step 2: Populate date dimension
-- Open SSMS → File → Open → 04_populate_date_dimension.sql → Execute
```

**Verify:**
```sql
USE Orders;
SELECT COUNT(*) FROM dbo.orders_;  -- Should return 0 (empty table)
SELECT COUNT(*) FROM dbo.dim_date; -- Should return number of dates
```

### 2. Python Setup (2 minutes)

```bash
# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import pandas, sqlalchemy, pyodbc; print('All packages installed!')"
```

### 3. Configure Data Ingestion (1 minute)

Edit `data_ingestion.py` if needed:
```python
# Line ~150: Update server name if not localhost
SERVER = 'localhost'  # Change if needed

# Line ~151: Update database name if different
DATABASE = 'Orders'

# Line ~152: Update file path if CSV is in different location
FILE_PATH = 'orders.csv'
```

### 4. Load Data (2 minutes)

```bash
# Run data ingestion
python data_ingestion.py

# Check log file for details
# data_ingestion.log
```

**Verify in SQL Server:**
```sql
SELECT COUNT(*) AS total_rows FROM dbo.orders_;
SELECT TOP 5 * FROM dbo.orders_;
```

### 5. Power BI Setup (10 minutes)

1. **Open Power BI Desktop**

2. **Connect to SQL Server:**
   - Get Data → SQL Server → Connect
   - Server: `localhost`
   - Database: `Orders`
   - Data Connectivity Mode: Import
   - Click OK

3. **Load Tables:**
   - Select `dbo.orders_` and `dbo.dim_date`
   - Click Load

4. **Create Relationship:**
   - Click Model view (left sidebar)
   - Drag `orders_[order_date]` to `dim_date[date_value]`
   - Verify relationship shows "1" on dim_date side, "*" on orders_ side

5. **Add Measures:**
   - Right-click `orders_` table → New measure
   - Copy each measure from `PowerBI_DAX_Measures.txt`
   - Paste and name the measure
   - Repeat for all measures

6. **Build First Visual:**
   - Create a new page: "Executive Dashboard"
   - Add a Card visual
   - Drag `[Total Sales]` measure to Fields
   - Format as currency

7. **Continue Building:**
   - Follow `PowerBI_Dashboard_Specification.md` for complete dashboard

## Quick Test Queries

### SQL Server Test
```sql
-- Test KPI query
SELECT 
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM dbo.orders_;

-- Test stored procedure
EXEC sp_TopProductsByRevenue @TopN = 5;
```

### Python Test
```python
from data_ingestion import OrdersDataIngestion

# Test connection
ingestion = OrdersDataIngestion()
print("Connection successful!")

# Test query
results = ingestion.run_stored_procedure('sp_TopProductsByRevenue', {'TopN': 5})
print(results)

ingestion.close_connections()
```

### Power BI Test
- Create a simple table visual with:
  - Rows: `orders_[segment]`
  - Values: `[Total Sales]`
- Should display data if everything is connected correctly

## Common Issues & Solutions

### Issue: "Cannot connect to SQL Server"
**Solution:**
- Verify SQL Server is running: Services → SQL Server (MSSQLSERVER)
- Check server name: Use `localhost` or `localhost\SQLEXPRESS` for Express edition
- Verify Windows Authentication or SQL credentials

### Issue: "ODBC Driver not found"
**Solution:**
- Download and install: [ODBC Driver 17 for SQL Server](https://docs.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server)
- Or use `ODBC Driver 18 for SQL Server` if available

### Issue: "Power BI cannot see tables"
**Solution:**
- Verify tables exist: `SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo'`
- Check database name matches: `USE Orders;`
- Try refreshing connection in Power BI

### Issue: "Python script fails on data load"
**Solution:**
- Check CSV file exists and path is correct
- Verify CSV has required columns (see README)
- Check data types match expected format
- Review `data_ingestion.log` for detailed errors

## Next Steps

1. ✅ Complete setup
2. ✅ Load sample data
3. ✅ Verify SQL queries work
4. ✅ Build Power BI dashboards
5. ✅ Schedule data refresh
6. ✅ Share dashboards with team

## Need Help?

- Check `README.md` for detailed documentation
- Review `data_ingestion.log` for Python errors
- Check SQL Server error logs for database issues
- Review Power BI query diagnostics for connection issues

---

**Estimated Total Setup Time:** 20-30 minutes
