/*
**************************************************************
Data Quality Check
**************************************************************
Script Purpose:
->  This script checks the quality of the data that will be 
	displayed in the following views:
	- dim_products
	- dim_customers
	- fact_sales
Usage:
->  Use to check the data quality of the silver layer
**************************************************************
*/

/*DIMENSION TABLE: dim_customers
Checking data discrepencies from joining tables*/
SELECT DISTINCT
	cst_gndr,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid;

--Checking data quality of gender column
SELECT  DISTINCT
gender
FROM gold.dim_customers;

/*DIMENSION TABLE: dim_products
Filtering historical data*/
select
*
from silver.crm_prd_info
WHERE prd_end_dt IS NULL;

/*FACT TABLE: fact_sales
Adding foreign keys*/
SELECT
sd.sls_ord_num,
sd.sls_prd_key,
dp.product_key, --foreign key
dc.customer_key --foreign key
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products dp
ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dIm_customers dc
ON sd.sls_cust_id = dc.customer_id;
