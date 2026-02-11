# Power BI Dashboard Specification
## Orders Analytics Solution

---

## **Connection Setup**

1. **Connect to SQL Server:**
   - Data Source: SQL Server
   - Server: `localhost` (or your SQL Server instance)
   - Database: `Orders`
   - Import Mode: Import (for better performance) or DirectQuery (for real-time)

2. **Load Tables:**
   - `dbo.orders_` (Fact table)
   - `dbo.dim_date` (Date dimension)

3. **Create Relationship:**
   - `orders_[order_date]` → `dim_date[date_value]` (Many-to-One)
   - Ensure relationship is active and set to single direction

---

## **Page 1: Executive Sales Performance**

### **Visuals:**

1. **KPI Cards (Top Row):**
   - **Total Sales** - Card visual using `[Total Sales]` measure
   - **Total Profit** - Card visual using `[Total Profit]` measure
   - **Profit Margin %** - Card visual using `[Profit Margin %]` measure
   - **Orders Count** - Card visual using `[Orders Count]` measure
   - **Average Order Value** - Card visual using `[Average Order Value]` measure

2. **Line Chart - Sales Trend:**
   - **Title:** "Sales YTD vs Sales LY"
   - **Axis:** `dim_date[month_name]` (or `dim_date[date_value]` for continuous)
   - **Values:** 
     - `[Sales YTD]` (Line 1)
     - `[Sales LY]` (Line 2)
   - **Legend:** Show both measures
   - **Format:** Enable data labels, smooth lines

3. **Bar Chart - Segment Performance:**
   - **Title:** "Total Sales and Profit by Segment"
   - **Axis:** `orders_[segment]`
   - **Values:** 
     - `[Total Sales]` (Bar 1)
     - `[Total Profit]` (Bar 2)
   - **Visualization Type:** Clustered Column Chart
   - **Format:** Add data labels, different colors for Sales vs Profit

4. **Map/Bar Chart - Regional Sales:**
   - **Option A - Map Visual:**
     - **Title:** "Total Sales by Region"
     - **Location:** `orders_[state]` or `orders_[region]`
     - **Size:** `[Total Sales]`
     - **Tooltip:** Region, Total Sales, Total Profit, Orders Count
   
   - **Option B - Bar Chart (if map not available):**
     - **Title:** "Total Sales by Region"
     - **Axis:** `orders_[region]`
     - **Values:** `[Total Sales]`
     - **Sort:** Descending by Total Sales

5. **Slicers:**
   - **Year Slicer:** `dim_date[year]` (Dropdown or List)
   - **Month Slicer:** `dim_date[month_name]` (Dropdown or List)
   - **Segment Slicer:** `orders_[segment]` (Checkbox or Dropdown)
   - **Region Slicer:** `orders_[region]` (Checkbox or Dropdown)

### **Layout:**
- Top row: 5 KPI cards
- Second row: Line chart (full width)
- Third row: Segment bar chart (left) + Regional map/bar (right)
- Bottom: Slicers panel

---

## **Page 2: Product & Category Performance**

### **Visuals:**

1. **Bar Chart - Sales by Category:**
   - **Title:** "Total Sales by Category"
   - **Axis:** `orders_[category]`
   - **Values:** `[Total Sales]`
   - **Visualization Type:** Column Chart
   - **Format:** Sort descending, add data labels

2. **Bar Chart - Sales by Sub-Category:**
   - **Title:** "Total Sales by Sub-Category"
   - **Axis:** `orders_[sub_category]`
   - **Values:** `[Total Sales]`
   - **Visualization Type:** Column Chart
   - **Format:** Sort descending, add data labels
   - **Cross-filter:** Enable drill-through to product details

3. **Table - Top N Products:**
   - **Title:** "Top 10 Products by Revenue"
   - **Columns:**
     - `orders_[product_id]`
     - `orders_[sub_category]`
     - `[Total Sales]` (formatted as currency)
     - `[Total Profit]` (formatted as currency)
     - `[Profit Margin %]` (formatted as percentage)
     - `[Total Quantity]`
   - **Filter:** Top 10 by `[Total Sales]`
   - **Format:** Conditional formatting for Profit Margin % (green/red)

4. **Matrix - Category vs Sub-Category:**
   - **Title:** "Sales Matrix: Category × Sub-Category"
   - **Rows:** `orders_[category]`
   - **Columns:** `orders_[sub_category]`
   - **Values:** `[Total Sales]`, `[Total Profit]`
   - **Format:** Conditional formatting, show values as currency

5. **Slicers:**
   - **Category Slicer:** `orders_[category]`
   - **Sub-Category Slicer:** `orders_[sub_category]`
   - **Top N Slicer:** Parameter (10, 20, 50, 100)

### **Layout:**
- Top row: Category and Sub-Category bar charts (side by side)
- Middle: Top N Products table (full width)
- Bottom: Category × Sub-Category matrix
- Right sidebar: Slicers

---

## **Page 3: Discount Impact**

### **Visuals:**

1. **KPI Cards:**
   - **Total Discount** - Card using `[Total Discount]` measure
   - **Net Sales** - Card using `[Net Sales]` measure
   - **Avg Discount %** - Card using `[Avg Discount %]` measure
   - **Profit Margin %** - Card using `[Profit Margin %]` measure

2. **Scatter Chart - Discount vs Profitability:**
   - **Title:** "Discount Impact on Profitability"
   - **X-Axis:** `orders_[discount]` (Average)
   - **Y-Axis:** `[Profit Margin %]` (Average)
   - **Size:** `[Total Sales]`
   - **Legend:** `orders_[category]` or `orders_[segment]`
   - **Format:** Add trend line, enable tooltips

3. **Bar Chart - Discount Ranges:**
   - **Title:** "Sales and Profit by Discount Range"
   - **Axis:** Create calculated column for discount ranges:
     ```
     Discount Range = 
     SWITCH(
         TRUE(),
         orders_[discount] = 0, "No Discount",
         orders_[discount] <= 10, "Low (1-10%)",
         orders_[discount] <= 20, "Medium (11-20%)",
         orders_[discount] <= 30, "High (21-30%)",
         "Very High (>30%)"
     )
     ```
   - **Values:** `[Total Sales]`, `[Total Profit]`
   - **Visualization Type:** Clustered Column Chart

4. **Line Chart - Discount Trend:**
   - **Title:** "Average Discount % Over Time"
   - **Axis:** `dim_date[date_value]` (by Month)
   - **Values:** `[Avg Discount %]`
   - **Format:** Show data labels, add reference line for target

5. **Table - Discount Analysis:**
   - **Columns:**
     - Discount Range
     - Order Count
     - Total Sales
     - Total Profit
     - Profit Margin %
     - Avg Discount %

### **Layout:**
- Top row: 4 KPI cards
- Second row: Scatter chart (left) + Discount ranges bar chart (right)
- Third row: Discount trend line chart (full width)
- Bottom: Discount analysis table

---

## **Page 4: Customer / Region Behavior**

### **Visuals:**

1. **Map Visual - Sales by State/Region:**
   - **Title:** "Sales Distribution by State"
   - **Location:** `orders_[state]`
   - **Size:** `[Total Sales]`
   - **Color:** `[Profit Margin %]` (gradient)
   - **Tooltip:** State, City, Total Sales, Total Profit, Orders Count

2. **Bar Chart - Sales by Region:**
   - **Title:** "Sales Performance by Region"
   - **Axis:** `orders_[region]`
   - **Values:** `[Total Sales]`, `[Total Profit]`
   - **Visualization Type:** Clustered Column Chart

3. **Bar Chart - Sales by Segment:**
   - **Title:** "Sales by Customer Segment"
   - **Axis:** `orders_[segment]`
   - **Values:** `[Total Sales]`
   - **Visualization Type:** Column Chart

4. **Bar Chart - Sales by Ship Mode:**
   - **Title:** "Sales Distribution by Ship Mode"
   - **Axis:** `orders_[ship_mode]`
   - **Values:** `[Total Sales]`
   - **Visualization Type:** Column Chart

5. **Treemap - Region × Segment:**
   - **Title:** "Sales Treemap: Region × Segment"
   - **Group:** `orders_[region]`, `orders_[segment]`
   - **Values:** `[Total Sales]`
   - **Format:** Color by `[Profit Margin %]`

6. **Table - Top Cities:**
   - **Title:** "Top 20 Cities by Sales"
   - **Columns:**
     - `orders_[city]`
     - `orders_[state]`
     - `orders_[region]`
     - `[Total Sales]`
     - `[Total Profit]`
     - `[Orders Count]`
   - **Filter:** Top 20 by `[Total Sales]`

7. **Slicers:**
   - **Region Slicer:** `orders_[region]`
   - **Segment Slicer:** `orders_[segment]`
   - **Ship Mode Slicer:** `orders_[ship_mode]`
   - **State Slicer:** `orders_[state]` (with search)

### **Layout:**
- Top left: Map visual (large)
- Top right: Region and Segment bar charts (stacked)
- Middle: Ship Mode bar chart + Treemap (side by side)
- Bottom: Top Cities table (full width)
- Right sidebar: Slicers

---

## **General Formatting Guidelines**

### **Theme:**
- Use a professional color scheme (e.g., blue/green for positive metrics, red for alerts)
- Consistent font: Segoe UI, 10-12pt for visuals, 14-16pt for titles

### **Interactions:**
- Enable cross-filtering between visuals
- Set appropriate filter interactions (highlight vs filter)
- Enable drill-through from summary to detail pages

### **Tooltips:**
- Add informative tooltips to all visuals
- Include relevant measures and dimensions
- Format numbers consistently (currency, percentage, whole numbers)

### **Mobile Layout:**
- Create mobile-optimized versions of key pages
- Stack visuals vertically for mobile
- Prioritize KPI cards and key charts

---

## **Data Refresh Setup**

1. **Schedule Refresh:**
   - Power BI Service → Dataset → Schedule Refresh
   - Set frequency (daily, weekly, etc.)
   - Configure data source credentials

2. **Incremental Refresh (if using DirectQuery):**
   - Configure incremental refresh policies
   - Set date range for historical vs incremental data

3. **Gateway Configuration:**
   - Install On-Premises Data Gateway if SQL Server is on-premises
   - Configure gateway with SQL Server credentials

---

## **Notes:**
- All measures should be added to a "Measures" table or the `orders_` table
- Use calculated columns for discount ranges and other categorizations
- Test all visuals with sample data before finalizing
- Document any custom DAX calculations beyond the provided measures
