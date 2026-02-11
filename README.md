# Orders Analytics - End-to-End Solution

A comprehensive analytics solution for Orders data using SQL Server, Python, and Power BI.

---

## 📋 Project Overview

This solution provides a complete data pipeline from raw CSV/Excel data to interactive Power BI dashboards, enabling data-driven decision making for sales and operations teams.

### Components:
1. **SQL Server Database** - Data storage and analytical queries
2. **Python Data Pipeline** - Data ingestion, transformation, and automation
3. **Power BI Dashboards** - Interactive visualizations and analytics

---

## 🗂️ Project Structure

```
Python Project/
│
├── orders.csv                          # Sample orders data (input file)
│
├── SQL Scripts/
│   ├── 01_database_setup.sql          # Database and table creation
│   ├── 02_kpi_queries.sql             # KPI calculation queries
│   ├── 03_analytical_queries.sql      # Stored procedures and analytical queries
│   └── 04_populate_date_dimension.sql # Date dimension population
│
├── Python Scripts/
│   ├── data_ingestion.py              # Main data ingestion and automation script
│   └── requirements.txt               # Python dependencies
│
├── Power BI/
│   ├── PowerBI_DAX_Measures.txt       # DAX measures for Power BI
│   └── PowerBI_Dashboard_Specification.md  # Dashboard design specification
│
└── README.md                           # This file
```

---

## 🚀 Setup Instructions

### Prerequisites

1. **SQL Server**
   - SQL Server 2016 or later (Express edition is sufficient)
   - SQL Server Management Studio (SSMS)
   - ODBC Driver 17 for SQL Server (or later)

2. **Python**
   - Python 3.8 or later
   - pip package manager

3. **Power BI Desktop**
   - Power BI Desktop (free download from Microsoft)

### Step 1: SQL Server Setup

1. **Open SQL Server Management Studio** and connect to your SQL Server instance

2. **Run the SQL scripts in order:**
   ```sql
   -- 1. Create database and tables
   -- Execute: 01_database_setup.sql
   
   -- 2. Populate date dimension
   -- Execute: 04_populate_date_dimension.sql
   ```

3. **Verify tables are created:**
   ```sql
   USE Orders;
   SELECT COUNT(*) FROM dbo.orders_;
   SELECT COUNT(*) FROM dbo.dim_date;
   ```

### Step 2: Python Environment Setup

1. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Verify SQL Server connection:**
   - Update `SERVER` variable in `data_ingestion.py` if your SQL Server is not on `localhost`
   - For Windows Authentication, ensure your Windows user has access to SQL Server
   - For SQL Authentication, update `username` and `password` parameters

### Step 3: Data Ingestion

1. **Place your CSV/Excel file** in the project directory (or update the path in `data_ingestion.py`)

2. **Run the data ingestion script:**
   ```bash
   python data_ingestion.py
   ```

3. **Verify data loaded:**
   ```sql
   SELECT COUNT(*) AS total_rows FROM dbo.orders_;
   SELECT TOP 10 * FROM dbo.orders_;
   ```

### Step 4: Power BI Setup

1. **Open Power BI Desktop**

2. **Connect to SQL Server:**
   - Get Data → SQL Server
   - Server: `localhost` (or your SQL Server instance)
   - Database: `Orders`
   - Import Mode: Import (recommended for better performance)

3. **Load Tables:**
   - Select `dbo.orders_` and `dbo.dim_date`
   - Click Load

4. **Create Relationship:**
   - Model view → Drag `orders_[order_date]` to `dim_date[date_value]`
   - Ensure relationship is active

5. **Add DAX Measures:**
   - Copy measures from `PowerBI_DAX_Measures.txt`
   - Create a new table called "Measures" or add measures to `orders_` table
   - Paste and create each measure

6. **Build Dashboards:**
   - Follow the specifications in `PowerBI_Dashboard_Specification.md`
   - Create 4 pages as described

---

## 📊 Key Features

### SQL Server Analytics

- **KPI Queries:** Total revenue, profit, orders count, regional performance
- **Top Products Analysis:** Top 10 products by revenue and profit
- **Dimensional Analysis:** Revenue and profit by segment, category, region
- **Time Intelligence:** Monthly sales trends, year-over-year comparisons
- **Stored Procedures:** Reusable analytical queries
- **T-SQL Cursor Example:** Row-by-row processing for audit tables

### Python Automation

- **Data Ingestion:** Read CSV/Excel files, clean and transform data
- **Data Loading:** Bulk insert into SQL Server using pandas and SQLAlchemy
- **Cursor-Based Updates:** Update discounts by region programmatically
- **Product Statistics:** Automated logging of product performance metrics
- **Stored Procedure Execution:** Run SQL stored procedures from Python
- **Incremental Loading:** Load only new records based on date filters

### Power BI Dashboards

- **Page 1 - Executive Sales Performance:**
  - KPI cards (Sales, Profit, Margin, Orders, AOV)
  - Sales YTD vs LY trend
  - Segment and regional performance
  - Interactive slicers

- **Page 2 - Product & Category Performance:**
  - Category and sub-category analysis
  - Top N products table
  - Category × Sub-Category matrix

- **Page 3 - Discount Impact:**
  - Discount vs profitability scatter chart
  - Discount range analysis
  - Discount trend over time

- **Page 4 - Customer/Region Behavior:**
  - Geographic sales map
  - Segment and ship mode analysis
  - Top cities table

---

## 🔍 Key Insights & Analysis

### Revenue Performance
- **Total Revenue:** Sum of all sales across all orders
- **Top Products:** Identify high-revenue products for inventory focus
- **Regional Performance:** Compare sales across different regions

### Profitability Analysis
- **Profit Margin:** Calculate profit as percentage of sales
- **Segment Profitability:** Compare profit margins across customer segments
- **Category Performance:** Identify most profitable product categories

### Discount Impact
- **Discount vs Profitability:** Analyze correlation between discount levels and profit margins
- **Optimal Discount Range:** Identify discount ranges that maximize profit
- **Discount Trends:** Monitor discount usage over time

### Customer Behavior
- **Segment Analysis:** Understand buying patterns by customer segment
- **Geographic Distribution:** Identify high-performing regions and cities
- **Ship Mode Preferences:** Analyze shipping preferences by region/segment

---

## 🔄 Data Refresh Process

### Automated Refresh Workflow

1. **New Data Arrives:**
   - Place new CSV/Excel file in designated folder

2. **Run Python Script:**
   ```bash
   python data_ingestion.py
   ```
   - Script reads new data
   - Cleans and transforms
   - Loads to SQL Server (append mode)

3. **Update Statistics:**
   - Script automatically logs product statistics
   - Updates discount adjustments if configured

4. **Power BI Refresh:**
   - Power BI Service: Schedule automatic refresh
   - Or manually refresh in Power BI Desktop

### Incremental Loading

The Python script supports incremental loading:
```python
# Load only new records since last load date
ingestion.incremental_load(df_clean, last_load_date='2024-01-01')
```

---

## 📈 SQL Queries Examples

### Top 10 Products by Revenue
```sql
EXEC sp_TopProductsByRevenue @TopN = 10;
```

### Revenue by Segment
```sql
EXEC sp_RevenueByDimension @Dimension = 'SEGMENT';
```

### Monthly Sales Trend
```sql
EXEC sp_MonthlySalesTrend @StartYear = 2022, @EndYear = 2023;
```

### Discount Impact Analysis
```sql
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 10 THEN 'Low (1-10%)'
        WHEN discount <= 20 THEN 'Medium (11-20%)'
        WHEN discount <= 30 THEN 'High (21-30%)'
        ELSE 'Very High (>30%)'
    END AS discount_range,
    SUM(sale_price * quantity) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
FROM dbo.orders_
GROUP BY 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 10 THEN 'Low (1-10%)'
        WHEN discount <= 20 THEN 'Medium (11-20%)'
        WHEN discount <= 30 THEN 'High (21-30%)'
        ELSE 'Very High (>30%)'
    END;
```

---

## 🛠️ Troubleshooting

### SQL Server Connection Issues
- Verify SQL Server is running
- Check Windows Authentication or SQL credentials
- Ensure ODBC Driver 17+ is installed
- Test connection using SSMS first

### Python Import Errors
- Ensure all packages are installed: `pip install -r requirements.txt`
- Check Python version: `python --version` (should be 3.8+)
- Verify SQL Server ODBC driver is accessible

### Power BI Connection Issues
- Verify SQL Server is accessible from Power BI Desktop
- Check firewall settings
- Ensure database and tables exist
- Test connection in Power BI before loading data

### Data Type Mismatches
- Check CSV column names match expected format
- Verify date formats are consistent (YYYY-MM-DD)
- Ensure numeric columns don't contain text values

---

## 📝 Customization

### Adding New Measures
1. Add DAX measures to `PowerBI_DAX_Measures.txt`
2. Copy to Power BI Desktop
3. Use in dashboard visuals

### Adding New Dimensions
1. Add columns to `dbo.orders_` table
2. Update Python transformation logic
3. Refresh Power BI dataset
4. Add new visuals to dashboards

### Modifying Discount Logic
```python
# Example: Update discounts by region
ingestion.update_discounts_by_region({
    'South': 0.5,    # Increase discount by 0.5%
    'West': -1.0     # Decrease discount by 1.0%
})
```

---

## 📚 Additional Resources

- [SQL Server Documentation](https://docs.microsoft.com/sql/)
- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [DAX Guide](https://dax.guide/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

---

## 🎯 Business Value

### Decision Support
- **Sales Strategy:** Identify top-performing products and regions
- **Pricing Optimization:** Analyze discount impact on profitability
- **Inventory Management:** Focus on high-revenue, high-margin products
- **Customer Segmentation:** Understand buying patterns by segment

### Automation Benefits
- **Time Savings:** Automated data loading reduces manual effort
- **Data Quality:** Consistent transformation logic ensures data accuracy
- **Scalability:** Handles large datasets efficiently
- **Refreshability:** Easy to update with new data

### Reporting Benefits
- **Self-Service Analytics:** Business users can explore data independently
- **Real-Time Insights:** Power BI provides up-to-date visualizations
- **Interactive Dashboards:** Drill-down capabilities for detailed analysis
- **Mobile Access:** Power BI mobile app for on-the-go access

---

## 📄 License

This project is provided as-is for educational and business use.

---

## 👤 Author

Created as part of an end-to-end analytics solution demonstration.

---

## 🔄 Version History

- **v1.0** - Initial release with complete SQL Server, Python, and Power BI solution

---

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section
2. Review SQL Server and Power BI logs
3. Verify data file format matches expected structure

---

**Last Updated:** February 2025
