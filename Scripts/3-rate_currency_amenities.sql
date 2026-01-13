/*
===============================================================================
Script Purpose:
	Checking Total number of properties with price and the ones that don't have total price.  
	
	Then creating priceItems table which will be derived from Gold table (price_items column) 
		because this column is in json format with keys and values (rate, currency, total, priceItems). 

	Creating amenties View also will be derived from Gold table, transforming amenties
		because this column is in Array format with values ([1, 3, 5, 7, 89, ....]). 

    The priceItems Table represents the price items for each property in the Fact_Table.
	The amenties View represents the All the amenties for each property in the Fact_Table.

    It performs transformations and Pivoting from json format to normal table from the Gold table 
    to produce a clean, enriched, and business-ready dataset.
===============================================================================
*/

USE MyDatabase;

-- No total price - 1080
SELECT 
	id,
	price_items
FROM airbnb.GOLD
WHERE price_items LIKE '%None%';

-- With total price - 1280
SELECT 
	price_items,
	LEN(price_items) AS price_items_length
FROM airbnb.GOLD
WHERE price_items NOT LIKE '%None%'
ORDER BY LEN(price_items) DESC;


-- Get rate, currency, total
CREATE VIEW cleaned_priceItems AS (
	SELECT
		id,
		[rate],
		[currency],
		COALESCE([total], 0) AS total,
		[priceItems]
	FROM 
	(
		SELECT 
			id, 
			[key] ,
			[value]
		FROM(
				SELECT 
					id, 
					REPLACE( REPLACE(price_items, '''', '"')  , ': None', ': null' ) as price_items
				FROM airbnb.GOLD
	
		)j
		CROSS APPLY OPENJSON(price_items)
	) unclP
	PIVOT
	(
		MAX([value])
		FOR [key] IN ([rate], [currency], [total], [priceItems])
	) p
)

-- Create priceItems table
IF OBJECT_ID('airbnb.price_items', 'U') IS NOT NULL
    DROP TABLE airbnb.price_items;
GO

CREATE TABLE airbnb.price_items (
	id INT,
	rate INT,
	currency NVARCHAR(50)
);
GO

INSERT INTO airbnb.price_items (
	id,
	rate,
	currency
)

SELECT
	id,
	rate,
	currency
FROM cleaned_priceItems;


SELECT * FROM airbnb.price_items;





-- ========================================================================================================================================






-- Clean amenity_id column

CREATE TABLE amenities_lookup (
	amenity_id INT PRIMARY KEY,
	amenity_name NVARCHAR(100)
)

INSERT INTO amenities_lookup VALUES
(2, 'Kitchen'),
(4, 'Wifi'),
(5, 'Air conditioning'),
(7, 'Pool'),
(8, 'Kitchen'),
(9, 'Free parking on premises'),
(11, 'Smoking allowed'),
(12, 'Pets allowed'),
(15, 'Gym'),
(16, 'Breakfast'),
(21, 'Elevator'),
(25, 'Hot tub'),
(27, 'Indoor fireplace'),
(30, 'Heating'),
(33, 'Washer'),
(34, 'Dryer'),
(35, 'Smoke alarm'),
(36, 'Carbon monoxide alarm'),
(41, 'Shampoo'),
(44, 'Hangers'),
(45, 'Hair dryer'),
(46, 'Iron'),
(47, 'Laptop-friendly workspace'),
(51, 'Self check-in'),
(58, 'TV'),
(64, 'High chair'),
(78, 'Private bathroom'),
(109, 'Wide hallways'),
(110, 'No stairs or steps to enter'),
(111, 'Wide entrance for guests'),
(112, 'Step-free path to entrance'),
(113, 'Well-lit path to entrance'),
(114, 'Disabled parking spot'),
(115, 'No stairs or steps to enter'),
(116, 'Wide entrance'),
(117, 'Extra space around bed'),
(118, 'Accessible-height bed'),
(120, 'No stairs or steps to enter'),
(121, 'Wide doorway to guest bathroom'),
(123, 'Bathtub with bath chair'),
(125, 'Accessible-height toilet'),
(127, 'No stairs or steps to enter'),
(128, 'Wide entryway'),
(136, 'Handheld shower head'),
(286, 'Crib'),
(288, 'Electric profiling bed'),
(289, 'Mobile hoist'),
(290, 'Pool with pool hoist'),
(291, 'Ceiling hoist'),
(294, 'Fixed grab bars for shower'),
(295, 'Fixed grab bars for toilet'),
(296, 'Step-free shower'),
(297, 'Shower chair'),
(347, 'Piano'),
(608, 'Extra space around toilet'),
(609, 'Extra space around shower');

-- Turn amenityIds strings to valid JSON
SELECT 
	id,
	CAST(value AS INT) AS amenity_id 
FROM airbnb.Gold
CROSS APPLY OPENJSON( Replace(amenityIds, '''', '') )

IF OBJECT_ID('airbnb.amenities', 'U') IS NOT NULL
    DROP VIEW IF EXISTS airbnb.amenities;
GO

CREATE VIEW airbnb.amenities AS (
	SELECT 
		l.id,
		a.amenity_name
	FROM airbnb.Gold l
	CROSS APPLY OPENJSON(l.amenityIds) j
	LEFT JOIN amenities_lookup a
	ON a.amenity_id = CAST(j.value AS INT)
	WHERE a.amenity_name IS NOT NULL AND l.price_items NOT LIKE '%None%'
)

SELECT *  FROM airbnb.amenities;

