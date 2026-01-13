/*
===============================================================================
Script Purpose:
	Checking columns one by one to finalize Fact_table
    Then creates Fact_table Table. 
    The Fact_table Table as its named represents the Fact data.

    It performs transformations and combines data from the Gold table 
    to produce a clean, enriched, and business-ready dataset.
===============================================================================
*/

USE MyDatabase;

-- -- Checking columns one by one to finalize Fact_table

--- Check Row duplicates
SELECT *
FROM (
   SELECT 
		*, 
		ROW_NUMBER() OVER (
              PARTITION BY 
				property_id,
				name_, 
				category,
				property_type,
				is_superhost,
				cancel_policy,
				owner_id, 
				bathrooms,
				bedrooms,
				beds,
				persons,
				reviews_count,
				rating,
				check_in,
				check_out 
              ORDER BY (SELECT NULL)
          ) AS rn
   FROM airbnb.Fact_table
) t
WHERE rn > 1;

---- Check for Nulls or duplicates in primary key (id)
SELECT 
	id, COUNT(*) AS row_count
FROM airbnb.Fact_table
GROUP BY id
HAVING COUNT(*) > 1 or id IS NULL;

---- Check for Nulls in (property_id)
SELECT 
	property_id
FROM airbnb.Fact_table
WHERE property_id IS NULL

---- Check for unwanted spaces (name_)
SELECT
	name_
FROM airbnb.Fact_table
WHERE name_ != TRIM(name_)

---- Check for distinct and Nulls (bathrooms)
SELECT DISTINCT
	bathrooms
FROM airbnb.Fact_table
ORDER BY bathrooms

SELECT 
	bathrooms
FROM airbnb.Fact_table
WHERE bathrooms IS NULL

---- Check for distinct (bedrooms) // there should be at least one bedroom
SELECT DISTINCT
	bedrooms
FROM airbnb.Fact_table
ORDER BY bedrooms

---- Check for distinct (beds) // there should be at least one bed
SELECT DISTINCT
	beds
FROM airbnb.Fact_table
ORDER BY beds

---- Check for invalid rooms and bathrooms (bathrooms, bedrooms, beds)
SELECT 
	bathrooms, bedrooms, beds
FROM airbnb.Fact_table
--WHERE bedrooms > beds
WHERE bathrooms > bedrooms -- // 113 bathrooms > bedrooms

---- Check for distinct and Nulls (rating)
SELECT DISTINCT
	rating
FROM airbnb.Fact_table
WHERE rating IS NULL 

SELECT DISTINCT
	rating
FROM airbnb.Fact_table
ORDER BY rating

---- Check owners (301) and properties (386) distinct count
---- Check each owner (301) Has how many properties (386)
---- Check if there is properties linked to more than one owner (owner_Id)
SELECT DISTINCT
	COUNT(DISTINCT  property_id) as property,
	COUNT(DISTINCT  owner_id) as owner_1
FROM airbnb.Fact_table

SELECT DISTINCT
	owner_id,
	COUNT(DISTINCT  property_id) as property
FROM airbnb.Fact_table
GROUP BY owner_id
ORDER BY COUNT(DISTINCT  property_id) DESC

SELECT DISTINCT
	property_id,
	COUNT(DISTINCT  owner_id) as owner_1
FROM airbnb.Fact_table
GROUP BY property_id
HAVING COUNT(DISTINCT  owner_id) > 1

--- Check distinct and standard values (cancel_property)
SELECT DISTINCT
	cancel_policy
FROM airbnb.Fact_table;


---- Check for INVALID DATE ORDERS (check_in, check_out)
SELECT 
	*
FROM airbnb.Fact_table
where check_in > check_out

-- Transformation

---- Transform Gold table to Final Fact_table table

---- Expectation: No Result


IF OBJECT_ID('airbnb.Fact_table', 'U') IS NOT NULL
    DROP TABLE airbnb.Fact_table;
GO

CREATE TABLE airbnb.Fact_table (
	id               INT,
    property_id      NVARCHAR(50),
    name_            NVARCHAR(255), 
	category         NVARCHAR(50),
	property_type    NVARCHAR(50),
	is_superhost     NVARCHAR(50),
	cancel_policy    NVARCHAR(255),
	owner_id         INT, 
	bathrooms        INT,
    bedrooms         INT,
	beds             INT,
	persons          INT,
	reviews_count    INT,
	rating           DECIMAL(10, 2),
	check_in         DATE,
	check_out        DATE
);
GO

INSERT INTO airbnb.Fact_table (
	id,
    property_id,
    name_, 
	category,
	property_type,
	is_superhost,
	cancel_policy,
	owner_id, 
	bathrooms,
    bedrooms,
	beds,
	persons,
	reviews_count,
	rating,
	check_in,
	check_out        
)

SELECT 
	id,
	property_id,
    TRIM(name_) AS name_,
	CASE 
		-- Categorize by property name
		WHEN TRIM(name_) LIKE '%chalet%'       THEN 'Chalet' -- 17
		WHEN TRIM(name_) LIKE '%suite%'        THEN 'Suite' -- 53
		WHEN TRIM(name_) LIKE '%hotel%'        THEN 'Hotel' -- 49

		WHEN TRIM(name_) LIKE '%studi%' 
		OR TRIM(name_) LIKE '%stuido%' 
		OR TRIM(name_) LIKE '%astidio%' 
		OR TRIM(name_) LIKE '%stadduyu%'    THEN 'Studio' -- 1082

		WHEN TRIM(name_) LIKE '%apartment%' 
		OR TRIM(name_) LIKE '%apt%' 
		OR TRIM(name_) LIKE '%appartment%' 
		OR TRIM(name_) LIKE '%aprtment%'    THEN 'Apartment' -- 968

		WHEN TRIM(name_) LIKE '%penthouse%' 
		OR TRIM(name_) LIKE '%villa%' 
		OR TRIM(name_) LIKE '%condo%' 
		OR TRIM(name_) LIKE '%flat%'        THEN 'Penthouse' -- 56

		WHEN TRIM(name_) LIKE '%room%'         THEN 'Room' -- 135

		-- Categorize by property type (for unspecified property name)
		WHEN property_type in ('Entire rental unit', 'Entire serviced apartment') THEN 'Apartment' 
		WHEN property_type in ('Entire cabin', 'Entire chalet') THEN 'Chalet' 
		WHEN property_type in ('Entire condo', 'Entire home') THEN 'Penthouse' 
		WHEN property_type in ('Private room in rental unit', 'Private room in home', 'Private room') THEN 'Studio' 

		ELSE 'Unknown'
	END AS category,
	property_type,
	isSuperhost AS is_superhost,
	LEFT( UPPER( REPLACE( 
					REPLACE( cancelPolicy, '_', ' ' ),
					'CANCEL ', 
				'') 
		), 
		1 
	) 
	+
	SUBSTRING( LOWER( REPLACE( 
		        REPLACE( cancelPolicy, '_', ' ' ),
		        'CANCEL ', 
		    '') 
	       ), 
		2,
		LEN(cancelPolicy) 
	) AS cancel_policy,
	owner_Id AS owner_id,
    COALESCE(FLOOR(bathrooms), 0) as bathrooms,
	CASE
		WHEN bedrooms = 0 THEN 1
		ELSE bedrooms
	END AS bedrooms,
	CASE
		WHEN beds < bedrooms THEN bedrooms
		WHEN beds = 0 THEN 1
		ELSE beds
	END AS beds,
	persons,
	reviewsCount AS reviews_count,
	COALESCE(rating, 0) as rating,
	check_in,
	check_out
FROM airbnb.Gold;

SELECT * FROM airbnb.Fact_table;