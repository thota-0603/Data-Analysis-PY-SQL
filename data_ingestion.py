"""
Orders Analytics - Data Ingestion and Automation Script
Reads CSV/Excel data, cleans and transforms it, loads into SQL Server
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
import pyodbc
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_ingestion.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class OrdersDataIngestion:
    """Class to handle data ingestion and transformation for Orders dataset"""
    
    def __init__(self, server='localhost', database='Orders', username=None, password=None, 
                 driver='ODBC Driver 17 for SQL Server', use_windows_auth=True):
        """
        Initialize connection parameters
        
        Args:
            server: SQL Server instance name
            database: Database name
            username: SQL Server username (if not using Windows auth)
            password: SQL Server password (if not using Windows auth)
            driver: ODBC driver name
            use_windows_auth: Use Windows Authentication if True
        """
        self.server = server
        self.database = database
        self.driver = driver
        
        if use_windows_auth:
            connection_string = (
                f"DRIVER={{{driver}}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"Trusted_Connection=yes;"
            )
        else:
            connection_string = (
                f"DRIVER={{{driver}}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"UID={username};"
                f"PWD={password};"
            )
        
        # Create SQLAlchemy engine
        connection_url = URL.create("mssql+pyodbc", query={"odbc_connect": connection_string})
        self.engine = create_engine(connection_url)
        
        # Create pyodbc connection for cursor-based operations
        self.pyodbc_conn = pyodbc.connect(connection_string)
        self.cursor = self.pyodbc_conn.cursor()
        
        logger.info(f"Connected to SQL Server: {server}/{database}")
    
    def read_data(self, file_path, file_type='csv'):
        """
        Read raw CSV/Excel data into DataFrame
        
        Args:
            file_path: Path to the data file
            file_type: 'csv' or 'excel'
        
        Returns:
            DataFrame with raw data
        """
        try:
            if file_type.lower() == 'csv':
                df = pd.read_csv(file_path)
            elif file_type.lower() in ['excel', 'xlsx', 'xls']:
                df = pd.read_excel(file_path)
            else:
                raise ValueError(f"Unsupported file type: {file_type}")
            
            logger.info(f"Read {len(df)} rows from {file_path}")
            return df
        except Exception as e:
            logger.error(f"Error reading file {file_path}: {str(e)}")
            raise
    
    def clean_and_transform(self, df):
        """
        Clean and transform columns (data types, handling nulls, computing derived columns)
        
        Args:
            df: Raw DataFrame
        
        Returns:
            Transformed DataFrame ready for SQL Server
        """
        logger.info("Starting data cleaning and transformation...")
        
        # Create a copy to avoid modifying original
        df_clean = df.copy()
        
        # Rename columns to match SQL table (handle case variations)
        column_mapping = {
            'Order Id': 'order_id',
            'Order Date': 'order_date',
            'Ship Mode': 'ship_mode',
            'Segment': 'segment',
            'Country': 'country',
            'City': 'city',
            'State': 'state',
            'Postal Code': 'postal_code',
            'Region': 'region',
            'Category': 'category',
            'Sub Category': 'sub_category',
            'Product Id': 'product_id',
            'Quantity': 'quantity',
            'Discount Percent': 'discount',
            'cost price': 'cost_price',
            'Cost Price': 'cost_price',
            'List Price': 'list_price',
            'list price': 'list_price'
        }
        
        df_clean = df_clean.rename(columns=column_mapping)
        
        # Convert order_date to datetime
        if 'order_date' in df_clean.columns:
            df_clean['order_date'] = pd.to_datetime(df_clean['order_date'], errors='coerce')
        
        # Ensure order_id is integer
        if 'order_id' in df_clean.columns:
            df_clean['order_id'] = pd.to_numeric(df_clean['order_id'], errors='coerce').astype('Int64')
        
        # Ensure quantity is integer
        if 'quantity' in df_clean.columns:
            df_clean['quantity'] = pd.to_numeric(df_clean['quantity'], errors='coerce').fillna(0).astype(int)
        
        # Convert discount to decimal (assuming percentage)
        if 'discount' in df_clean.columns:
            df_clean['discount'] = pd.to_numeric(df_clean['discount'], errors='coerce').fillna(0)
        
        # Calculate sale_price from list_price and discount
        if 'list_price' in df_clean.columns and 'discount' in df_clean.columns:
            df_clean['sale_price'] = df_clean['list_price'] * (1 - df_clean['discount'] / 100)
            df_clean['sale_price'] = df_clean['sale_price'].round(2)
        elif 'sale_price' not in df_clean.columns:
            logger.warning("sale_price not found and cannot be calculated")
            df_clean['sale_price'] = 0
        
        # Calculate profit = (sale_price - cost_price) * quantity
        if 'cost_price' in df_clean.columns and 'sale_price' in df_clean.columns:
            df_clean['profit'] = (df_clean['sale_price'] - df_clean['cost_price']) * df_clean['quantity']
            df_clean['profit'] = df_clean['profit'].round(2)
        elif 'profit' not in df_clean.columns:
            logger.warning("profit not found and cannot be calculated")
            df_clean['profit'] = 0
        
        # Fill nulls in text columns
        text_columns = ['ship_mode', 'segment', 'country', 'city', 'state', 
                       'postal_code', 'region', 'category', 'sub_category', 'product_id']
        for col in text_columns:
            if col in df_clean.columns:
                df_clean[col] = df_clean[col].fillna('Unknown').astype(str)
        
        # Select only the columns needed for SQL table
        required_columns = [
            'order_id', 'order_date', 'ship_mode', 'segment', 'country', 'city',
            'state', 'postal_code', 'region', 'category', 'sub_category',
            'product_id', 'quantity', 'discount', 'sale_price', 'profit'
        ]
        
        # Keep only required columns that exist
        available_columns = [col for col in required_columns if col in df_clean.columns]
        df_clean = df_clean[available_columns]
        
        # Remove rows with null order_id
        df_clean = df_clean.dropna(subset=['order_id'])
        
        logger.info(f"Data transformation complete. {len(df_clean)} rows ready for loading.")
        logger.info(f"Columns: {list(df_clean.columns)}")
        
        return df_clean
    
    def load_to_sql(self, df, table_name='orders_', if_exists='append', chunk_size=1000):
        """
        Load data into SQL Server using pandas to_sql
        
        Args:
            df: Cleaned DataFrame
            table_name: Target table name
            if_exists: 'append', 'replace', or 'fail'
            chunk_size: Number of rows to insert per batch
        """
        try:
            logger.info(f"Loading {len(df)} rows to {table_name}...")
            
            df.to_sql(
                name=table_name,
                con=self.engine,
                schema='dbo',
                if_exists=if_exists,
                index=False,
                method='multi',
                chunksize=chunk_size
            )
            
            logger.info(f"Successfully loaded {len(df)} rows to dbo.{table_name}")
        except Exception as e:
            logger.error(f"Error loading data to SQL Server: {str(e)}")
            raise
    
    def update_discounts_by_region(self, discount_adjustments):
        """
        Update discounts by region using cursor-based logic
        
        Args:
            discount_adjustments: Dictionary with region as key and discount adjustment as value
                Example: {'South': 0.5, 'West': -1.0}
        """
        logger.info("Updating discounts by region...")
        
        try:
            for region, adjustment in discount_adjustments.items():
                # Update discount for orders in this region
                update_query = """
                    UPDATE dbo.orders_
                    SET discount = discount + ?
                    WHERE region = ?
                """
                
                self.cursor.execute(update_query, (adjustment, region))
                rows_affected = self.cursor.rowcount
                logger.info(f"Updated {rows_affected} rows for region '{region}' with adjustment {adjustment}")
            
            self.pyodbc_conn.commit()
            logger.info("Discount updates committed successfully")
        except Exception as e:
            self.pyodbc_conn.rollback()
            logger.error(f"Error updating discounts: {str(e)}")
            raise
    
    def log_product_statistics(self):
        """
        Log product statistics into a separate table using cursor-based logic
        """
        logger.info("Logging product statistics...")
        
        try:
            # Create product statistics table if it doesn't exist
            create_table_query = """
            IF OBJECT_ID('dbo.product_statistics', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.product_statistics (
                    stat_id INT IDENTITY(1,1) PRIMARY KEY,
                    product_id VARCHAR(50),
                    category VARCHAR(50),
                    sub_category VARCHAR(50),
                    total_revenue DECIMAL(10,2),
                    total_profit DECIMAL(10,2),
                    total_quantity INT,
                    order_count INT,
                    profit_margin_pct DECIMAL(5,2),
                    log_date DATETIME DEFAULT GETDATE()
                );
            END
            """
            
            self.cursor.execute(create_table_query)
            self.pyodbc_conn.commit()
            
            # Calculate and insert product statistics
            stats_query = """
                INSERT INTO dbo.product_statistics 
                    (product_id, category, sub_category, total_revenue, total_profit, 
                     total_quantity, order_count, profit_margin_pct)
                SELECT 
                    product_id,
                    category,
                    sub_category,
                    SUM(sale_price * quantity) AS total_revenue,
                    SUM(profit) AS total_profit,
                    SUM(quantity) AS total_quantity,
                    COUNT(DISTINCT order_id) AS order_count,
                    ROUND(SUM(profit) / NULLIF(SUM(sale_price * quantity), 0) * 100, 2) AS profit_margin_pct
                FROM dbo.orders_
                GROUP BY product_id, category, sub_category
            """
            
            self.cursor.execute(stats_query)
            rows_inserted = self.cursor.rowcount
            self.pyodbc_conn.commit()
            
            logger.info(f"Logged statistics for {rows_inserted} products")
        except Exception as e:
            self.pyodbc_conn.rollback()
            logger.error(f"Error logging product statistics: {str(e)}")
            raise
    
    def run_stored_procedure(self, proc_name, params=None):
        """
        Execute a stored procedure
        
        Args:
            proc_name: Name of the stored procedure
            params: Dictionary of parameters {param_name: param_value}
        """
        try:
            logger.info(f"Executing stored procedure: {proc_name}")
            
            if params:
                # Build parameterized query
                param_names = ', '.join([f"@{k}=?" for k in params.keys()])
                query = f"EXEC {proc_name} {param_names}"
                param_values = list(params.values())
                self.cursor.execute(query, param_values)
            else:
                self.cursor.execute(f"EXEC {proc_name}")
            
            # Fetch results if any
            results = self.cursor.fetchall()
            self.pyodbc_conn.commit()
            
            logger.info(f"Stored procedure {proc_name} executed successfully")
            return results
        except Exception as e:
            self.pyodbc_conn.rollback()
            logger.error(f"Error executing stored procedure {proc_name}: {str(e)}")
            raise
    
    def incremental_load(self, df, order_date_column='order_date', last_load_date=None):
        """
        Perform incremental load based on order_date
        
        Args:
            df: DataFrame to load
            order_date_column: Column name containing order date
            last_load_date: Last date already loaded (datetime or string)
        """
        try:
            if last_load_date:
                if isinstance(last_load_date, str):
                    last_load_date = pd.to_datetime(last_load_date)
                
                # Filter data for new records
                df['order_date'] = pd.to_datetime(df[order_date_column], errors='coerce')
                df_new = df[df['order_date'] > last_load_date].copy()
                
                logger.info(f"Filtered {len(df_new)} new records since {last_load_date}")
            else:
                df_new = df.copy()
                logger.info("No last_load_date provided, loading all records")
            
            if len(df_new) > 0:
                self.load_to_sql(df_new, if_exists='append')
            else:
                logger.info("No new records to load")
        except Exception as e:
            logger.error(f"Error in incremental load: {str(e)}")
            raise
    
    def close_connections(self):
        """Close database connections"""
        self.cursor.close()
        self.pyodbc_conn.close()
        self.engine.dispose()
        logger.info("Database connections closed")


def main():
    """Main execution function"""
    # Configuration
    SERVER = 'localhost'  # Change to your SQL Server instance
    DATABASE = 'Orders'
    FILE_PATH = 'orders.csv'  # Path to your CSV file
    
    # Initialize ingestion class
    ingestion = OrdersDataIngestion(server=SERVER, database=DATABASE)
    
    try:
        # Step 1: Read raw data
        logger.info("=" * 60)
        logger.info("Step 1: Reading raw data")
        logger.info("=" * 60)
        df_raw = ingestion.read_data(FILE_PATH, file_type='csv')
        
        # Step 2: Clean and transform
        logger.info("=" * 60)
        logger.info("Step 2: Cleaning and transforming data")
        logger.info("=" * 60)
        df_clean = ingestion.clean_and_transform(df_raw)
        
        # Step 3: Load to SQL Server
        logger.info("=" * 60)
        logger.info("Step 3: Loading data to SQL Server")
        logger.info("=" * 60)
        ingestion.load_to_sql(df_clean, if_exists='replace')  # Use 'append' for incremental loads
        
        # Step 4: Update discounts by region (example)
        logger.info("=" * 60)
        logger.info("Step 4: Updating discounts by region")
        logger.info("=" * 60)
        # Uncomment to apply discount adjustments
        # ingestion.update_discounts_by_region({
        #     'South': 0.5,
        #     'West': -1.0
        # })
        
        # Step 5: Log product statistics
        logger.info("=" * 60)
        logger.info("Step 5: Logging product statistics")
        logger.info("=" * 60)
        ingestion.log_product_statistics()
        
        # Step 6: Run stored procedures
        logger.info("=" * 60)
        logger.info("Step 6: Running stored procedures")
        logger.info("=" * 60)
        # Example: Get top 10 products
        results = ingestion.run_stored_procedure('sp_TopProductsByRevenue', {'TopN': 10})
        if results:
            logger.info("Top 10 Products by Revenue:")
            for row in results[:5]:  # Show first 5
                logger.info(f"  {row}")
        
        logger.info("=" * 60)
        logger.info("Data ingestion completed successfully!")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"Error in main execution: {str(e)}")
        raise
    finally:
        ingestion.close_connections()


if __name__ == "__main__":
    main()
