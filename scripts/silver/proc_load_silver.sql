/*
************************************************************************************
Stored Procedure: Load Silver Layer (Bronze -> Silver)
************************************************************************************
Script Purpose:
  -> This script loads data from the bronze.crm & bronze.erp tables into the 
     appropriate silver.crm & silver.erp tables
  -> It truncates the tables before loading the data.

Parameters:
  -> This stored procedure does not accept parameters nor return any values.

Usage example:
  EXEC bronze.load_bronze;
************************************************************************************
*/

CREATE OR ALTER   PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @layer_start_time DATETIME, @layer_end_time DATETIME;
	BEGIN TRY
		PRINT '**********************************'
		PRINT 'Loading Silver Layer'
		PRINT '**********************************'

		PRINT '----------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '----------------------------------'
		
		SET @start_time = GETDATE();
		SET @layer_start_time = GETDATE();
		--Silver TABLE 1: crm_cust_info
		PRINT '-> Truncating table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '-> Inserting data into: silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
			)

		SELECT
		cst_id,
		cst_key,

		--Data cleansing: Removing unnecessary spaces
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,

		--Data Normalization: mapping vales to meaningful descriptions
		CASE UPPER(TRIM(cst_marital_status))
			 WHEN 'S' THEN 'Single'
			 WHEN 'M' THEN 'Married'
			 ELSE 'n/a'--Handling NULLs by using default values
		END cst_marital_status,

		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		FROM (
			SELECT
			*,
			--Identifying duplicates
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
			) t
		WHERE flag_last = 1;-- Data filtering

		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		SET @start_time = GETDATE();
		--silver TABLE 2: crm_prd_info
		PRINT '-> Truncating table: silver.crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '-> Inserting data into: silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
			)

		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,--Derived column: Category ID
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,--Derived column: Product Key
			prd_nm,
			COALESCE(prd_cost, 0) AS prd_cost,--Handling NULLs and non-negatives

			--Data Normalization: mapping product line values to meaningful descriptions
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a' --Handling NULLs
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			--Ensuring end date ends one day before start date of new start date
			CAST(
				LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE
				) AS prd_end_dt
		FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		SET @start_time = GETDATE();
		--silver TABLE 3: crm_sales_details
		PRINT '-> Truncating table: silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '-> Inserting data into: silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
			END AS sls_order_dt,
			CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_ship_dt,
			CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
			END AS sls_due_dt,
			CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
				  THEN sls_quantity * ABS(sls_price)
			 ELSE sls_sales 
		END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL or sls_price = 0 THEN sls_sales / sls_quantity
			 WHEN sls_price < 0 THEN ABS(sls_price)
			 ELSE sls_price 
		END AS sls_price
		FROM bronze.crm_sales_details;

		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		PRINT '----------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '----------------------------------'

		SET @start_time = GETDATE();
		--silver TABLE 4: erp_cust_az12
		PRINT '-> Truncating table: silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '-> Inserting data into: silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)

		SELECT 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				 ELSE cid
			END AS cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				 ELSE bdate
			END AS bdate,--Set future dates to NULL
			CASE
				 WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen--Data Normalization and NULL handling
		FROM bronze.erp_cust_az12;

		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		SET @start_time = GETDATE();
		--silver TABLE 5: erp_loc_a101
		PRINT '-> Truncating table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '-> Inserting data into: silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101 (
			cid, 
			cntry
		)

		SELECT 
			REPLACE(cid, '-','') AS cid, --Remove unnecessary characters
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				 WHEN TRIM(cntry) IS NULL THEN 'n/a'
				 ELSE cntry
			END AS cntry --Data standardization
		FROM bronze.erp_loc_a101;

		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		SET @start_time = GETDATE();
		--silver TABLE 6: erp_px_cat_g1v2
		PRINT '-> Truncating table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '-> Inserting data into: silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)

		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '-> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '----------------'

		SET @layer_end_time = GETDATE();
		PRINT '**********************************'
		PRINT 'SILVER LAYER DATA LOAD COMPLETE'
		PRINT '-> Full Load Duration: ' + CAST(DATEDIFF(second, @layer_start_time, @layer_end_time) AS NVARCHAR) + ' seconds'
		PRINT '**********************************'
		END TRY
	BEGIN CATCH
		PRINT '*****************************************'
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();		
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR)
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT '*****************************************'
	END CATCH
END;
