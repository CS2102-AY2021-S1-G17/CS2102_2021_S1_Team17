DROP FUNCTION IF EXISTS po_view_pets;
DROP FUNCTION IF EXISTS po_view_past_trans;
DROP FUNCTION IF EXISTS ct_view_capable;
DROP FUNCTION IF EXISTS ct_view_past_trans;

/*
SELECT * FROM po_view_pets(...);
*/

CREATE OR REPLACE FUNCTION po_view_pets(_phone INTEGER) 
	RETURNS TABLE (name VARCHAR, category_name VARCHAR, special_requirements VARCHAR(500)) AS
$$
BEGIN
	RETURN QUERY (
		SELECT P.name, P.category_name, P.special_requirements
		FROM owns_pet P
		WHERE P.phone = _phone
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM po_view_past_trans(...);
*/

CREATE OR REPLACE FUNCTION po_view_past_trans(_phone INTEGER) 
	RETURNS TABLE (
		caretaker VARCHAR, pet_name VARCHAR, start_date DATE, end_date DATE, 
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY (
		SELECT C.name AS caretaker, B.pet_name, B.start_date, B.end_date, 
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, care_taker C
		WHERE B.po_phone = _phone AND C.phone = B.ct_phone AND B.status = 'Success'
		ORDER BY B.start_date
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_capable(...);
*/

CREATE OR REPLACE FUNCTION ct_view_capable(_phone INTEGER)
	RETURNS TABLE (category_name VARCHAR, daily_price FLOAT8) AS
$$
BEGIN
	RETURN QUERY (
		SELECT C.category_name, C.daily_price
		FROM capable C
		WHERE C.phone = _phone
		ORDER BY C.daily_price
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_past_trans(...);
*/

CREATE OR REPLACE FUNCTION ct_view_past_trans(_phone INTEGER) 
	RETURNS TABLE (
		petowner VARCHAR, pet_name VARCHAR, start_date DATE, end_date DATE, 
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY (
		SELECT P.name AS petowner, B.pet_name, B.start_date, B.end_date, 
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, pet_owner P
		WHERE B.ct_phone = _phone AND P.phone = B.po_phone AND B.status = 'Success'
		ORDER BY B.start_date
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_pending_bids(...);
*/

CREATE OR REPLACE FUNCTION ct_view_pending_bids(_phone INTEGER) 
	RETURNS TABLE (
		petowner VARCHAR, pet_name VARCHAR, start_date DATE, end_date DATE, 
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY (
		SELECT P.name AS petowner, B.pet_name, B.start_date, B.end_date, 
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, pet_owner P
		WHERE B.ct_phone = _phone AND P.phone = B.po_phone AND B.status = 'Pending'
		ORDER BY B.start_date
		);
END;
$$
LANGUAGE plpgsql;