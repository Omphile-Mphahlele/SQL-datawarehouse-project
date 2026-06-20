/* 
*************************************
CREATE DATABASE AND SCHEMAS
*************************************
Script purpose:
  - This script DROPS the existing 'DataWarehouse' database if it exists, and creates a new 'DataWarehouse' database. 
  - It also creates schemas 'bronze', 'silver' and 'gold'

NOTE:
  - When run, this script WILL DELETE the existing 'DataWarehouse' database along with the data stored inside. 
  - Ensure that neccessary backup has been taken before running this script.
*/

USE master;

--Checks whether the database exists, and drops it
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Creates a new 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

--Creates schemas 'bronze', 'silver' and 'gold' within the 'DataWarehouse' database
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
