--SELECT
/* 1. Write a query that returns everything in the customer table. */


SELECT *
FROM customer;

/* 2. Write a query that displays all of the columns and 10 rows from the cus- tomer table, 
sorted by customer_last_name, then customer_first_ name. */


SELECT *
FROM customer
ORDER BY customer_last_name ASC, customer_first_name ASC
LIMIT 10;

--WHERE
/* 1. Write a query that returns all customer purchases of product IDs 4 and 9. */
-- option 1


-- option 2

SELECT *
FROM customer_purchases
WHERE product_id = 4 OR product_id = 9;


/*2. Write a query that returns all customer purchases and a new calculated column 'price' (quantity * cost_to_customer_per_qty), 
@@ -28,9 +32,15 @@ filtered by vendor IDs between 8 and 10 (inclusive) using either:
*/
-- option 1

SELECT *, (quantity * cost_to_customer_per_qty) AS price
FROM customer_purchases
WHERE vendor_id >= 8 AND vendor_id <= 10;

-- option 2

SELECT *, (quantity * cost_to_customer_per_qty) AS price
FROM customer_purchases
WHERE vendor_id BETWEEN 8 AND 10;


--CASE
@@ -39,19 +49,38 @@ Using the product table, write a query that outputs the product_id and product_n
columns and add a column called prod_qty_type_condensed that displays the word “unit” 
if the product_qty_type is “unit,” and otherwise displays the word “bulk.” */

SELECT product_id, product_name
,CASE 
	WHEN product_qty_type = 'unit' THEN 'unit'
	ELSE 'bulk'
	END AS prod_qty_type_condensed
FROM product;


/* 2. We want to flag all of the different types of pepper products that are sold at the market. 
add a column to the previous query called pepper_flag that outputs a 1 if the product_name 
contains the word “pepper” (regardless of capitalization), and otherwise outputs 0. */


SELECT product_id, product_name
,CASE 
	WHEN product_qty_type = 'unit' THEN 'unit'
	ELSE 'bulk'
	END AS prod_qty_type_condensed
,CASE
	WHEN product_name LIKE '%pepper%' THEN 1
	ELSE 0
	END AS pepper_flag
FROM product;

--JOIN
/* 1. Write a query that INNER JOINs the vendor table to the vendor_booth_assignments table on the 
vendor_id field they both have in common, and sorts the result by vendor_name, then market_date. */


SELECT * 
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vba
ON v.vendor_id = vba.vendor_id
ORDER BY vendor_name, market_date;


/* SECTION 3 */
@@ -60,6 +89,11 @@ vendor_id field they both have in common, and sorts the result by vendor_name, t
/* 1. Write a query that determines how many times each vendor has rented a booth 
at the farmer’s market by counting the vendor booth assignments per vendor_id. */

SELECT *, COUNT(v.vendor_id) AS total_rental_num
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vba
ON v.vendor_id = vba.vendor_id
GROUP BY v.vendor_id;


/* 2. The Farmer’s Market Customer Appreciation Committee wants to give a bumper 
@@ -68,7 +102,13 @@ of customers for them to give stickers to, sorted by last name, then first name.
HINT: This query requires you to join two tables, use an aggregate function, and use the HAVING keyword. */


SELECT customer_last_name, customer_first_name, ROUND(SUM(quantity*cost_to_customer_per_qty),2) AS total_spending
FROM customer_purchases AS cp
LEFT JOIN customer AS c
ON cp.customer_id = c.customer_id
GROUP BY cp.customer_id
HAVING total_spending > 2000
ORDER BY customer_last_name, customer_first_name;

--Temp Table
/* 1. Insert the original vendor table into a temp.new_vendor and then add a 10th vendor: 
@@ -82,14 +122,26 @@ When inserting the new vendor, you need to appropriately align the columns to be
VALUES(col1,col2,col3,col4,col5) 
*/

DROP TABLE IF EXISTS new_vendor;

--make the TABLE
CREATE TEMP TABLE new_vendor AS
SELECT *
FROM vendor;

INSERT INTO new_vendor(vendor_id, vendor_name,vendor_type, vendor_owner_first_name,vendor_owner_last_name)
VALUES(CAST('10' AS INT), 'Thomass Superfood Store', 'Fresh Focused', 'Thomas', 'Rosenthal');

-- Date
/*1. Get the customer_id, month, and year (in separate columns) of every purchase in the customer_purchases table.
HINT: you might need to search for strfrtime modifers sqlite on the web to know what the modifers for month 
and year are! */

SELECT customer_id,
strftime('%m', market_date) AS purchase_month,
strftime('%Y', market_date) AS purchase_year
FROM customer_purchases;


/* 2. Using the previous query as a base, determine how much money each customer spent in April 2022. 
@@ -98,3 +150,11 @@ Remember that money spent is quantity*cost_to_customer_per_qty.
HINTS: you will need to AGGREGATE, GROUP BY, and filter...
but remember, STRFTIME returns a STRING for your WHERE statement!! */

SELECT customer_first_name, customer_last_name, ROUND(SUM(quantity*cost_to_customer_per_qty),2) AS total_spending,
strftime('%m', market_date) AS purchase_month,
strftime('%Y', market_date) AS purchase_year
FROM customer_purchases AS cp
LEFT JOIN customer AS c
ON cp.customer_id = c.customer_id
WHERE purchase_month LIKE '%4%' AND purchase_year = '2022'
GROUP BY c.customer_id;
  94 changes: 84 additions & 10 deletions94  
02_activities/assignments/assignment2.sql
Viewed
Original file line number	Diff line number	Diff line change
@@ -20,7 +20,13 @@ The `||` values concatenate the columns into strings.
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */


SELECT 
product_name || ', ' || product_size_updated|| ' (' || product_qty_type_updated || ')' as [list]
FROM 
(
	SELECT *, COALESCE(product_size, '') as product_size_updated, COALESCE(product_qty_type, 'unit') as product_qty_type_updated
	FROM product
	);

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
@@ -32,18 +38,40 @@ each new market date for each customer, or select only the unique market dates p
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT market_date, customer_id,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS rank
FROM customer_purchases;

SELECT DISTINCT market_date, customer_id,
  dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS rank
FROM customer_purchases;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */


SELECT market_date, customer_id, rank
FROM 
(
	SELECT market_date, customer_id,
	  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS rank
	FROM customer_purchases)
WHERE rank = 1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */


SELECT customer_first_name, customer_last_name, pro.product_name, p.purchase_number
FROM 
(
	SELECT DISTINCT customer_id, product_id,
	COUNT() OVER (PARTITION BY customer_id ORDER BY product_id DESC) AS [purchase_number]
	FROM customer_purchases) as p
LEFT JOIN customer as c 
ON p.customer_id = c.customer_id
LEFT JOIN product as pro
on p.product_id = pro.product_id;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
@@ -57,11 +85,18 @@ Remove any trailing or leading whitespaces. Don't just use a case statement for
Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */


SELECT product_id, product_name, product_size, product_qty_type,
CASE 
WHEN INSTR(product_name, '-')=0 THEN NULL
ELSE SUBSTR(product_name, (INSTR(product_name, '-')+2))
END as description
FROM product; 

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */


SELECT product_id, product_name, product_size
FROM product
WHERE product_size REGEXP '^[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.
@@ -73,7 +108,16 @@ HINT: There are a possibly a few ways to do this query, but if you're struggling
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


WITH temp as 
(
SELECT *, 
SUM(quantity*cost_to_customer_per_qty) OVER (PARTITION BY market_date ORDER BY market_date DESC) AS total_sales
FROM customer_purchases)
SELECT market_date,MAX(total_sales) as daily_total_sales
FROM temp
UNION
SELECT market_date,MIN(total_sales) as daily_total_sales
FROM temp;


/* SECTION 3 */
@@ -89,27 +133,43 @@ Think a bit about the row counts: how many distinct vendors, product names are t
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */


WITH temp as
(
SELECT count(customer_id) as total_customer
FROM customer)
SELECT v.vendor_name, p.product_name, 5*vi.product_id*vi.original_price*total_customer as total_profit
FROM vendor_inventory as vi
CROSS JOIN temp
LEFT JOIN vendor as v
ON v.vendor_id = vi.vendor_id
LEFT JOIN product as p
ON p.product_id = vi.product_id
GROUP BY vi.vendor_id, vi.product_id;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */


CREATE TABLE product_units as 
SELECT *, CURRENT_TIMESTAMP as snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */


INSERT INTO product_units
VALUES(28, 'AirPod', '100 grams', NULL, 'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 
HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/


DELETE FROM product_units
WHERE product_id = 28;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
@@ -129,5 +189,19 @@ Finally, make sure you have a WHERE statement to update the right row,
When you have all of these components, you can run the update statement. */


UPDATE product_units
SET current_quantity = (
  SELECT temp.current_quantity
  FROM 
  (
    SELECT product_id, IFNULL(quantity, 0) AS current_quantity
    FROM 
	(
      SELECT *,
             ROW_NUMBER() OVER (PARTITION BY vendor_id, product_id ORDER BY market_date DESC) AS rank
      FROM vendor_inventory)
    WHERE rank = 1
  ) AS temp
  WHERE temp.product_id = product_units.product_id);