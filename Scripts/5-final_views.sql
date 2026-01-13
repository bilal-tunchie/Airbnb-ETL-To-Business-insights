/*
===============================================================================
Script Purpose:
	Finally, after we cleaned the Fact table and seperated them into four tables
		to maintain each group efficiently, now it's time to join them all in one
		final view. 

	Createing view which will join all "Fact_table", "priceItems", "offers_discounts_taxes"
		and "price_And_Fees". 

Usage:
    - This views can be queried directly for analytics and reporting.
===============================================================================
*/

USE MyDatabase;

-- Joining all tables together - Removing all properties without total price

IF OBJECT_ID('airbnb.airbnb', 'U') IS NOT NULL
    DROP VIEW IF EXISTS airbnb.airbnb;
GO

CREATE VIEW airbnb.airbnb AS (
	SELECT
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
		rate,
		currency,
		total_before_taxes AS revenue,
		total_before_taxes - (total_before_taxes * 0.15) AS revenue_excluding_taxes,
		total_before_taxes * 0.15 AS taxes,
		price,
		nights,
		cleaning_fee,
		airbnb__service_fee,
		special_offer,
		weekly_stay_discount,
		early_bird_discount,
		long_stay_discount,
		check_in,
		check_out 
	FROM (
			SELECT 
				fct.id,
				fct.property_id,
				fct.name_, 
				fct.category,
				fct.property_type,
				fct.is_superhost,
				fct.cancel_policy,
				fct.owner_id, 
				fct.bathrooms,
				fct.bedrooms,
				fct.beds,
				fct.persons,
				fct.reviews_count,
				fct.rating,
				pri.rate,
				pri.currency,
				( 
					(pfs.price * pfs.nights) + pfs.cleaning_fee + pfs.airbnb__service_fee 
				) 
					-
				( 
					COALESCE(odt.special_offer, 0) + 
					COALESCE(odt.weekly_stay_discount, 0) + 
					COALESCE(odt.early_bird_discount, 0) +
					COALESCE(odt.long_stay_discount, 0)
				) AS total_before_taxes,
				pfs.price,
				pfs.nights,
				pfs.cleaning_fee,
				pfs.airbnb__service_fee,
				COALESCE(odt.special_offer, 0) AS special_offer,
				COALESCE(odt.weekly_stay_discount, 0) AS weekly_stay_discount,
				COALESCE(odt.early_bird_discount, 0) AS early_bird_discount,
				COALESCE(odt.long_stay_discount, 0) AS long_stay_discount,
				--total * 0.15 AS taxes,
				fct.check_in,
				fct.check_out 
			FROM airbnb.Fact_table fct
			INNER JOIN airbnb.price_items pri
			ON fct.id = pri.id
			INNER JOIN airbnb.price_and_fees pfs
			ON pri.id = pfs.id
			LEFT JOIN airbnb.offers_discounts_taxes odt
			ON pfs.id = odt.id
		)df
)


-- Final Views 

-- // Fact View for all listed properties
SELECT * FROM airbnb.airbnb;

-- // Dinmension View for all amenities per property
SELECT *  FROM airbnb.amenities;

--// Dinmension View showing address per property
SELECT *FROM airbnb.addresses;