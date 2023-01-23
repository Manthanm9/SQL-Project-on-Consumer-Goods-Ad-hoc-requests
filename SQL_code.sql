/*CODEBASICS SQL PROJECT CHALLENGE
  GENERATING INSIGHTS ON CONSUMER GOODS AD-HOC REQUEST FROM ATLIQ HARDWARE*/


/*REQUEST 1
Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";


/*REQUEST 2
What is the percentage of unique product increase in 2021 vs. 2020?*/

WITH unique_products AS (
    SELECT 
        fiscal_year, 
        COUNT(DISTINCT Product_code) as unique_products 
    FROM 
        fact_gross_price 
    GROUP BY 
        fiscal_year
)
SELECT 
    up_2020.unique_products as unique_products_2020,
    up_2021.unique_products as unique_products_2021,
    round((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) as percentage_change
FROM 
    unique_products up_2020
CROSS JOIN 
    unique_products up_2021
WHERE 
    up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021;
   
   
/*REQUEST 3
Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts.*/

SELECT segment, count(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


/*REQUEST 4
Which segment had the most increase in unique products in
2021 vs 2020?*/

WITH temp_table AS (
    SELECT 
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.Product_code) as product_count
    FROM 
        fact_sales_monthly s
        JOIN dim_product p ON s.product_code = p.product_code
    GROUP BY 
        p.segment,
        s.fiscal_year
)
SELECT 
    up_2020.segment,
    up_2020.product_count as product_count_2020,
    up_2021.product_count as product_count_2021,
    up_2021.product_count - up_2020.product_count as difference
FROM 
    temp_table as up_2020
JOIN 
    temp_table as up_2021
ON 
    up_2020.segment = up_2021.segment
    AND up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021
ORDER BY 
    difference DESC;


/* REQUEST 5
Get the products that have the highest and lowest manufacturing costs.*/

SELECT m.product_code, concat(product," (",variant,")") AS product, cost_year,manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
WHERE manufacturing_cost= 
(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
or 
manufacturing_cost = 
(SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY manufacturing_cost DESC;


/*REQUEST 6
Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market.*/

SELECT c.customer_code, c.customer, round(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
FROM fact_pre_invoice_deductions d
JOIN dim_customer c ON d.customer_code = c.customer_code
WHERE c.market = "India" AND fiscal_year = "2021"
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


/* REQUEST 7
Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.*/

WITH temp_table AS (
    SELECT customer,
    monthname(date) AS months ,
    month(date) AS month_number, 
    year(date) AS year,
    (sold_quantity * gross_price)  AS gross_sales
 FROM fact_sales_monthly s JOIN
 fact_gross_price g ON s.product_code = g.product_code
 JOIN dim_customer c ON s.customer_code=c.customer_code
 WHERE customer="Atliq exclusive"
)
SELECT months,year, concat(round(sum(gross_sales)/1000000,2),"M") AS gross_sales FROM temp_table
GROUP BY year,months
ORDER BY year,month_number;


/* REQUEST 8
In which quarter of 2020, got the maximum total_sold_quantity?*/

WITH temp_table AS (
  SELECT date,month(date_add(date,interval 4 month)) AS period, fiscal_year,sold_quantity 
FROM fact_sales_monthly
)
SELECT CASE 
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" END quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quanity_in_millions FROM temp_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quanity_in_millions DESC ;


/* REQUEST 9
Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution?*/

WITH temp_table AS (
      SELECT c.channel,sum(s.sold_quantity * g.gross_price) AS total_sales
  FROM
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT 
  channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM temp_table ;


/* REQUEST 10
Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?*/

WITH temp_table AS (
    select division, s.product_code, concat(p.product,"(",p.variant,")") AS product , sum(sold_quantity) AS total_sold_quantity,
    rank() OVER (partition by division order by sum(sold_quantity) desc) AS rank_order
 FROM
 fact_sales_monthly s
 JOIN dim_product p
 ON s.product_code = p.product_code
 WHERE fiscal_year = 2021
 GROUP BY product_code
)
SELECT * FROM temp_table
WHERE rank_order IN (1,2,3);
