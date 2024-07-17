-- Request 1 --
SELECT market from dim_customer where customer = "Atliq Exclusive" and region = "APAC";


-- Request 2 --
SELECT unique_products_2020, unique_products_2021, (unique_products_2021 - unique_products_2020 )* 100/ unique_products_2020 AS percentage_chg
from (
       SELECT
             (SELECT count(distinct product_code) FROM fact_sales_monthly where fiscal_year = 2020) AS unique_products_2020  , 
              (SELECT count(distinct product_code) FROM fact_sales_monthly where fiscal_year = 2021)  as unique_products_2021 
	 ) AS subquery;
 

 -- Request 3 --
SELECT segment, (SELECT count(distinct product_code) from dim_product) as product_count FROM dim_product group by segment ;


-- Request 4 -- 
WITH temp_table AS (SELECT p.segment, s.fiscal_year, COUNT(DISTINCT s.Product_code) as product_count FROM fact_sales_monthly s 
JOIN dim_product p ON s.product_code = p.product_code
    GROUP BY p.segment, s.fiscal_year )
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
   
   
-- Request 5 --
SELECT m.product_code, p.product, m.manufacturing_cost from fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT max(manufacturing_cost) from fact_manufacturing_cost) OR m.manufacturing_cost = (SELECT min(manufacturing_cost) from fact_manufacturing_cost ) ;


-- Request 6 --
WITH TAB1 AS (SELECT customer_code, round(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage FROM fact_pre_invoice_deductions d where fiscal_year = "2021" GROUP BY customer_code),
     TAB2 AS (SELECT customer_code, customer from dim_customer where market = "India")
SELECT TAB1.customer_code, TAB1.average_discount_percentage, TAB2.customer from TAB1
JOIN TAB2 on TAB1.customer_code = TAB2.customer_code
ORDER BY average_discount_percentage DESC 
LIMIT 5;


-- Request 7 --
SELECT CONCAT(MONTHNAME(FS.date), ' (', YEAR(FS.date), ')') AS 'Month', FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year ; 


-- Request 8 --
SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then CONCAT('[',1,'] ',MONTHNAME(date))  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then CONCAT('[',2,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then CONCAT('[',3,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then CONCAT('[',4,'] ',MONTHNAME(date))
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters;


-- Request 9 --
WITH Table_4 AS (
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
FROM Table_4 ;



-- Request 10 --
WITH temp_table AS (
    select division, s.product_code, p.product , sum(sold_quantity) AS total_sold_quantity,
    rank() OVER (partition by division order by sum(sold_quantity) desc) AS rank_order
 FROM
 fact_sales_monthly s
 JOIN dim_product p
 ON s.product_code = p.product_code
 WHERE fiscal_year = 2021
 GROUP BY division, product_code, product 
)
SELECT * FROM temp_table
WHERE rank_order IN (1,2,3);

 
