/*
*************************************************************************************************************
Quality Checks
*************************************************************************************************************
Script purpose:
-> This script performs various important data validation to ensure consistency, accuracy, and normalization.
-> The checks include:
   - NULL or duplicate PKs (Primary Keys)
   - Data Standardization & Consistency
   - Invalid dates, date ranges and date orders
   - Data consistency between related fields (Joining columns)

NOTE:
   - Run these checks after loading data into the silver layer.
   - Investigate and resolve discrepencies found while running these checks
*************************************************************************************************************
*/

/*TABLE 1: crm_cust_info
Checking for NULLs or Duplicates in PK*/
SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
ORDER BY COUNT(*) DESC;

/*Checking for unwanted spaces 
[Columns: cst_firstname, cst_lastname]*/
SELECT
	cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

/*Checking for data consistency (Data Normalization & Standardization)
[Columns: cst_marital_status, cst_gndr]*/
SELECT DISTINCT
	cst_gndr
FROM bronze.crm_cust_info;

/*TABLE 2: crm_prd_info
Appropriating Joining columns*/
SELECT
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
FROM bronze.crm_prd_info;

--Checking unwanted spaces
SELECT
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

/*Handling NULLs
[columns used: prd_cost, prd_line]*/
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL;

/*Checking date logic
[columns: prd_start_dt, prd_end_dt]*/
SELECT 
	prd_id,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_end_dt > prd_start_dt;

/*TABLE 3: crm_sales_details
Check unwanted spaces
[Columns: sls_ord_num, sls_prd_key]*/
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

/*Data type transformations
[Columns: sls_order_dt, sls_ship_dt, sls_due_dt]*/
SELECT
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
		 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt
FROM bronze.crm_sales_details

/*Checking data correctness (non-negatives, NULLs)
[Columns: sls_sales, sls_quantity, sls_price]*/
SELECT
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales <0 OR sls_quantity < 0 OR sls_price < 0
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL;

/*TABLE 4: erp_cust_az12
Appropriate joining column*/
SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		 ELSE cid
	END AS cid
FROM bronze.erp_cust_az12;

/*Check unwanted spaces
[Columns: cid, gen]*/
SELECT
*
FROM bronze.erp_cust_az12
WHERE gen != TRIM(gen);

--Checking date logic
SELECT
*
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE();

-- Checking data standardization (NULLS & Inconsistent data)
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

/*TABLE 5: erp_loc_a101
Checking unwanted spaces (All columns)*/
SELECT *
FROM bronze.erp_loc_a101
WHERE cntry != TRIM(cntry);

--Appropriate Joining column
SELECT
	REPLACE(cid, '-','') AS cid
FROM bronze.erp_loc_a101;

-- Checking data standardization (NULLS & Inconsistent data)
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101;

/*TABLE 6: erp_px_cat_g1v2
Checking duplicate or NULL PKs*/
SELECT 
	id,
	COUNT(*)
FROM bronze.erp_px_cat_g1v2
GROUP BY id;

--Checking unwanted spaces (All columns)
SELECT *
FROM bronze.erp_px_cat_g1v2;
WHERE id != TRIM(id);


