
/*
===============================================================================
Script Purpose:
	Creating RawJsonData view which will Parse the initial JSON array once per row 
		(Nights, fees, offers, discount and taxes). 

	Then we are creating two tables "offers_discounts_taxes" and "price_And_Fees". 

    It performs transformations and Pivoting from json format to normal table from the Gold table 
    to produce a clean, enriched, and business-ready dataset.
===============================================================================
*/


USE MyDatabase;

-- Get priceItems (Nights, fees, offers, discount and taxes)
CREATE VIEW RawJsonData AS (
   -- Step 1: Parse the initial JSON array once per row
   SELECT
       id,
       [key] AS item_index,
       [value] AS json_item
   FROM cleaned_priceItems
   CROSS APPLY OPENJSON(priceItems)
)

-- ========================================================================================================================================


-- Get Special offer, Weekly stay discount,  Early bird discount, Long stay discount and Taxes                                            

IF OBJECT_ID('airbnb.offers_discounts_taxes', 'U') IS NOT NULL
    DROP TABLE airbnb.offers_discounts_taxes;
GO

CREATE TABLE airbnb.offers_discounts_taxes (
	id INT,
	special_offer INT,
	weekly_stay_discount INT,
	early_bird_discount INT,
	long_stay_discount INT,
	taxes INT
);
GO

INSERT INTO airbnb.offers_discounts_taxes (
	id,
	special_offer,
	weekly_stay_discount,
	early_bird_discount,
	long_stay_discount,
	taxes
)

SELECT
	id,
	COALESCE(special_offer, 0) as special_offer, 
	COALESCE(weekly_stay_discount, 0) as weekly_stay_discount,
	COALESCE(early_bird_discount, 0) as early_bird_discount,
	COALESCE(long_stay_discount, 0) as long_stay_discount,
	COALESCE(taxes, 0) as taxes
FROM
(
	SELECT
		id,
		[Special offer] AS special_offer,
		[Weekly stay discount] AS weekly_stay_discount,
		[Early bird discount] AS early_bird_discount,
		[Long stay discount] AS long_stay_discount,
		[Taxes] AS taxes
	FROM 
	(
		SELECT
			id,
			JSON_VALUE(json_item, '$.title') AS title,
			CAST( JSON_VALUE(json_item, '$.amount') AS INT)  AS amount
		FROM RawJsonData
		WHERE 
			JSON_VALUE(json_item, '$.title') = 'Special offer' 
			OR JSON_VALUE(json_item, '$.title') LIKE '%discount'
			OR JSON_VALUE(json_item, '$.title') = 'Taxes'
	)gg
	PIVOT
	(
		   SUM([amount])
		   FOR [title] IN ( [Special offer], [Weekly stay discount], [Early bird discount], [Long stay discount], [Taxes] )
	) p
)fn


SELECT * FROM airbnb.offers_discounts_taxes;



-- ========================================================================================================================================



-- Get price and nights | Cleaning fee and Airbnb service fee

-- Price and Nights
CREATE VIEW price_Nights AS (
	SELECT
		id,
	   title,
	   -- 1. Extract Price: Everything from after '$' up to the first space
	   SUBSTRING( title, 2, CHARINDEX(' ', title) - 2 ) AS price,
	   -- 2. Extract Nights: Everything between 'x ' and the next space
	   SUBSTRING( title, CHARINDEX(' x ', title) + 3, 
			CHARINDEX(' ', title, CHARINDEX(' x ', title) + 3) - (CHARINDEX(' x ', title) + 3)
	   ) AS nights
	FROM 
	(
		SELECT
			id,
			JSON_VALUE(json_item, '$.title') AS title,
			JSON_VALUE(json_item, '$.amount') AS amount
		FROM RawJsonData
		WHERE 
			JSON_VALUE(json_item, '$.title') like '%nights' 
			OR JSON_VALUE(json_item, '$.title') like '%night'
	)pn
)

-- Cleaning fee and Airbnb service fee
CREATE VIEW clean_ServiceFee AS (
	SELECT
		Id,
		[Cleaning fee] as cleaning_fee,
		[Airbnb service fee] as airbnb_service_fee
	FROM 
	(
		SELECT
			id,
			JSON_VALUE(json_item, '$.title') AS title,
			JSON_VALUE(json_item, '$.amount') AS amount
		FROM RawJsonData
		WHERE 
			JSON_VALUE(json_item, '$.title') = 'Cleaning fee'
			OR JSON_VALUE(json_item, '$.title') = 'Airbnb service fee'
	)uncl
	PIVOT
	(
		   MAX([amount])
		   FOR [title] IN ([Cleaning fee], [Airbnb service fee])
	) p
)


-- Create priceItems table
IF OBJECT_ID('airbnb.price_and_fees', 'U') IS NOT NULL
    DROP TABLE airbnb.price_and_fees;
GO

CREATE TABLE airbnb.price_and_fees (
	Id INT,
	price INT,
	nights INT,
	cleaning_fee INT,
	airbnb__service_fee INT
);
GO

INSERT INTO airbnb.price_and_fees (
	Id,
	price,
	nights,
	cleaning_fee,
	airbnb__service_fee
)

SELECT 
	COALESCE(pn.id, csf.id) AS id,
	pn.price,
	pn.nights,
	COALESCE(csf.cleaning_fee, 0) AS cleaning_fee,
	COALESCE(csf.airbnb_service_fee, 0) AS airbnb_service_fee
FROM price_Nights pn
FULL OUTER JOIN clean_ServiceFee csf
ON pn.Id = csf.Id


SELECT * FROM airbnb.price_and_fees;
