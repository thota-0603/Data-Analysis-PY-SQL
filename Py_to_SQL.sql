
CREATE TABLE dbo.orders_ (
    order_id      INT           NOT NULL PRIMARY KEY,
    order_date    DATE          NULL,
    ship_mode     VARCHAR(20)   NULL,
    segment       VARCHAR(20)   NULL,
    country       VARCHAR(20)   NULL,
    city          VARCHAR(20)   NULL,
    state         VARCHAR(20)   NULL,
    postal_code   VARCHAR(20)   NULL,
    region        VARCHAR(20)   NULL,
    category      VARCHAR(20)   NULL,
    sub_category  VARCHAR(20)   NULL,
    product_id    VARCHAR(20)   NULL,
    quantity      INT           NULL,
    discount      DECIMAL(7,2)  NULL,
    sale_price    DECIMAL(7,2)  NULL,
    profit        DECIMAL(7,2)  NULL
);
select * from dbo.orders_;

--top 10 products
select top 10 product_id, sub_category, sum(sale_price) as total_sales
from dbo.orders_
group by product_id, sub_category
order by total_sales desc

--top 5 highest selling products in each region
with c as  (
select region,product_id,sum(sale_price) as sales
from dbo.orders_
group by region,product_id)
select * from (
select *
, row_number() over(partition by region order by sales desc) as rn
from c) A
where rn<=5
---------------------------
with cte as (
select year(order_date) as order_year,month(order_date) as order_month,
sum(sale_price) as sales
from dbo.orders_
group by year(order_date),month(order_date)
--order by year(order_date),month(order_date)
	)
select order_month
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by order_month
order by order_month
-------------


SELECT COUNT(*) as total_rows FROM dbo.orders_;


SELECT TOP 10
    product_id,
    sub_category,
    SUM(sale_price * quantity) AS total_revenue
FROM dbo.orders_
GROUP BY product_id, sub_category
ORDER BY total_revenue DESC
