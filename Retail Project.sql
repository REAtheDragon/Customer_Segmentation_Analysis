--- DATA VALIDATION ---

--- loading the 3 tables --

SELECT *
FROM retail.customer;

SELECT *
FROM retail.prod_cat_info;

SELECT *
FROM retail.transactions;  
 
--- creating a new tale to work with ----

CREATE TABLE retail_temp
LIKE retail.transactions;

--- checking for duplicates in the transaction table ---

SELECT transaction_id, ROW_NUMBER() OVER(PARTITION BY transaction_id, cust_id, tran_date, prod_cat_code, prod_subcat_code, Rate, Tax) as row_num
FROM retail.transactions;

WITH Dupli AS 
(SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id, cust_id, tran_date, prod_cat_code, prod_subcat_code, Rate, Tax) as row_num
FROM retail.transactions)
SELECT *
FROM Dupli
WHERE row_num > 1;

--- creating a new column in the table created to accomadate the row number making it possible to delete duplicates referencing it ---

ALTER TABLE retail_temp
ADD row_num INT;

--- inserted the row_num details into the column ---

INSERT INTO retail_temp
SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id, cust_id, tran_date, prod_cat_code, prod_subcat_code, Rate, Tax) as row_num
FROM retail.transactions;

--- deleting the duplcates ---

DELETE
FROM retail_temp
WHERE row_num > 1;

--- droping the row_num after making use of it as it is not useful anymore ---

ALTER TABLE retail_temp
DROP row_num;

--- converting negative values to positive in the qauntity, rate, and total amount columns and rounding up the total amount and tax columns to 2 decimal places as they are currencies --- 

SELECT qty, rate, total_amt, tax, ABS(qty), ABS(rate), ROUND(ABS(total_amt), 2), ROUND(tax, 2)
FROM retail_temp;

--- updating the correction in my table ---

UPDATE retail_temp
SET qty = ABS(qty), rate = ABS(rate), total_amt = ROUND(ABS(total_amt), 2), tax = ROUND(tax, 2);

--- converting date data in text to date format ----

SELECT tran_date, STR_TO_DATE(REPLACE(tran_date,'-','/'), '%d/%m/%Y')
FROM retail_temp;

--- updating the correction ---

UPDATE retail_temp
SET tran_date = STR_TO_DATE(REPLACE(tran_date,'-','/'), '%d/%m/%Y');

SELECT DISTINCT(store_type)
FROM retail_temp;

--- checking for duplicates in the  customer table ---

SELECT ROW_NUMBER() OVER(PARTITION BY customer_id, dob, gender, city_code) as row_num
FROM retail.customer;

WITH dupli AS
(SELECT ROW_NUMBER() OVER(PARTITION BY customer_id, dob, gender, city_code) as row_num
FROM retail.customer)
SELECT *
FROM dupli
WHERE row_num > 1;

--- converting date in text format to date format ---

SELECT dob, STR_TO_DATE(dob, '%d/%m/%Y')
FROM retail.customer;

--- updating corrections in table ---

UPDATE retail.customer
SET dob = STR_TO_DATE(dob, '%d/%m/%Y');

--- converting the gender column to a more understandable form ---

SELECT gender,
(CASE WHEN gender = 'F' THEN 'Female'
     WHEN gender = 'M' THEN 'Male'
     ELSE gender
     END)
     FROM retail.customer;
     
--- updating conversion to the table ---

UPDATE retail.customer
SET gender = CASE WHEN gender = 'F' THEN 'Female'
     WHEN gender = 'M' THEN 'Male'
     ELSE gender
     END;

--- checking for duplicates in the prod_cat_info table ---

SELECT ROW_NUMBER() OVER(PARTITION BY prod_cat_code, prod_cat, prod_sub_cat_code, prod_subcat) as row_num
FROM retail.prod_cat_info;

WITH dupli AS
(SELECT ROW_NUMBER() OVER(PARTITION BY prod_cat_code, prod_cat, prod_sub_cat_code, prod_subcat) as row_num
FROM retail.prod_cat_info)
SELECT *
FROM dupli
WHERE row_num > 1;

--- joining the 3 tables together for better data exploration ----

SELECT a.cust_id, tran_date, a.qty, a.rate, a.tax, a.total_amt, a.store_type,
b.dob, b.gender, b.city_code,
c.prod_cat, c.prod_subcat
FROM retail_temp AS a
LEFT JOIN 
retail. customer AS b
ON 
a.cust_id = b.customer_id
LEFT JOIN 
retail.prod_cat_info AS c
ON
a.prod_cat_code = c.prod_cat_code
AND
a.prod_subcat_code = c.prod_sub_cat_code
ORDER BY 1;



