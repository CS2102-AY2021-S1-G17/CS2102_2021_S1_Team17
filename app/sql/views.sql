DROP FUNCTION IF EXISTS po_view_pets;
DROP FUNCTION IF EXISTS po_view_past_trans;
DROP FUNCTION IF EXISTS ct_view_capable;
DROP FUNCTION IF EXISTS ct_view_past_trans;
DROP FUNCTION IF EXISTS po_view_upcoming_bids;
DROP FUNCTION IF EXISTS ct_view_pending_bids;
DROP FUNCTION IF EXISTS ct_view_future_work;
DROP FUNCTION IF EXISTS search_ct;
DROP FUNCTION IF EXISTS admin_view_unpaid_salary;
DROP FUNCTION IF EXISTS admin_view_accepted_bids;
DROP FUNCTION IF EXISTS ct_monthly_stats;
DROP FUNCTION IF EXISTS ct_view_bid_details;

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
		caretaker VARCHAR, ct_phone INTEGER, pet_name VARCHAR, category_name VARCHAR, start_date DATE, end_date DATE, 
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY (
		SELECT C.name AS caretaker, B.ct_phone, B.pet_name, B.category_name, B.start_date, B.end_date, 
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, care_taker C
		WHERE B.po_phone = _phone AND C.phone = B.ct_phone AND B.status = 'Success'
		ORDER BY B.start_date DESC
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
		petowner VARCHAR, po_phone INTEGER, pet_name VARCHAR, category_name VARCHAR, start_date DATE, end_date DATE, 
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY (
		SELECT P.name AS petowner, B.po_phone, B.pet_name, B.category_name, B.start_date, B.end_date, 
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, pet_owner P
		WHERE B.ct_phone = _phone AND P.phone = B.po_phone AND B.status = 'Success'
		ORDER BY B.start_date DESC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM po_view_upcoming_bids(...);
*/

CREATE OR REPLACE FUNCTION po_view_upcoming_bids(_phone INTEGER) 
	RETURNS TABLE (
		caretaker VARCHAR, ct_phone INTEGER, pet_name VARCHAR, start_date DATE, end_date DATE, status VARCHAR,
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, rating INTEGER, comment VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY(
		SELECT C.name AS caretaker, B.ct_phone, B.pet_name, B.start_date, B.end_date, B.status,
			B.total_cost, B.transfer_method, B.payment_method, B.rating, B.comment
		FROM bids B, care_taker C
		WHERE B.po_phone = _phone AND C.phone = B.ct_phone AND B.end_date >= CURRENT_DATE
		ORDER BY B.start_date ASC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_pending_bids(...);
*/

CREATE OR REPLACE FUNCTION ct_view_pending_bids(_phone INTEGER) 
    RETURNS TABLE (
        petowner VARCHAR, po_phone INTEGER, pet_name VARCHAR, start_date DATE, end_date DATE,
        total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, category VARCHAR, req VARCHAR(500)
        ) AS
$$
BEGIN
    RETURN QUERY(
        SELECT P.name AS petowner, B.po_phone, B.pet_name, B.start_date, B.end_date,
            B.total_cost, B.transfer_method, B.payment_method, O.category_name AS category, O.special_requirements AS req
        FROM bids B, pet_owner P, owns_pet O
        WHERE B.ct_phone = _phone AND B.status = 'Pending' AND P.phone = B.po_phone AND B.start_date >= CURRENT_DATE AND 
        O.phone = P.phone AND O.name = B.pet_name
        ORDER BY B.start_date ASC
        );
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_future_work(...);
*/

CREATE OR REPLACE FUNCTION ct_view_future_work(_phone INTEGER)
	RETURNS TABLE (
		petowner VARCHAR, po_phone INTEGER, pet_name VARCHAR, start_date DATE, end_date DATE,
		total_cost FLOAT8, transfer_method VARCHAR, payment_method VARCHAR, category VARCHAR, req VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY(
		SELECT P.name AS petowner, B.po_phone, B.pet_name, B.start_date, B.end_date,
			B.total_cost, B.transfer_method, B.payment_method, O.category_name AS category, O.special_requirements AS req
		FROM bids B, pet_owner P,  owns_pet O
		WHERE B.end_date >= CURRENT_DATE AND B.ct_phone = _phone AND B.status = 'Success' AND P.phone = B.po_phone
		AND O.phone = P.phone AND O.name = B.pet_name
		ORDER BY B.start_date ASC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM search_ct(...);
*/

CREATE OR REPLACE FUNCTION search_ct(_phone INTEGER, _category VARCHAR, _start_date DATE, _end_date DATE, _location VARCHAR)
	RETURNS TABLE (phone INTEGER, name VARCHAR, transfer_location VARCHAR, avg_rating FLOAT8) AS
$$
DECLARE
	loc VARCHAR;
BEGIN
	IF _location IS NOT NULL THEN
		loc := _location;
	ELSE
		SELECT P.transfer_location INTO loc FROM pet_owner P WHERE P.phone = _phone;
	END IF;
	RETURN QUERY(
		SELECT T.phone, T.name, T.transfer_location, T.avg_rating
		FROM care_taker T, capable C, availability A
		WHERE T.phone = C.phone AND T.phone = A.phone AND C.category_name = _category 
			AND A.available_date >= _start_date AND A.available_date <= _end_date
			AND A.remaining_limit > 0
		GROUP BY T.phone
		HAVING COUNT(DISTINCT A.available_date) = (_end_date - _start_date + 1)
		ORDER BY T.avg_rating DESC, 
		CASE WHEN T.transfer_location = _location THEN 1 ELSE 2 END ASC, 
		CASE WHEN T.is_full_time THEN 1 ELSE 2 END ASC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM admin_view_upcoming_bids();
*/

CREATE OR REPLACE FUNCTION admin_view_accepted_bids()
	RETURNS TABLE (
		po_phone INTEGER, ct_phone INTEGER, pet_name VARCHAR, start_date DATE, end_date DATE, 
		category_name VARCHAR, total_cost FLOAT8
		) AS
$$
BEGIN
	RETURN QUERY(
		SELECT po_phone, ct_phone, pet_name, start_date, end_date, category_name, total_cost
		FROM bids
		WHERE start_date >= CURRENT_DATE AND status = 'Accepted'
		ORDER BY start_date ASC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM admin_view_unpaid_salary();
*/

CREATE OR REPLACE FUNCTION admin_view_unpaid_salary()
	RETURNS TABLE (name VARCHAR, phone INTEGER, pay_time DATE, amount FLOAT8, pet_day INTEGER) AS
$$
BEGIN
	RETURN QUERY(
		SELECT C.name, S.phone, S.pay_time, S.amount, S.pet_day
		FROM salary S 
		LEFT JOIN pay P ON S.phone = P.ct_phone AND S.pay_time = P.pay_time
		LEFT JOIN care_taker C ON S.phone = C.phone
		WHERE S.amount > 0 AND P.ad_phone IS NULL
		ORDER BY S.pay_time ASC
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_monthly_stats(...);
*/

CREATE OR REPLACE FUNCTION ct_monthly_stats(_phone INTEGER, y INTEGER, m INTEGER)
	RETURNS TABLE (pay_time DATE, amount FLOAT8, pet_day INTEGER, num_bids BIGINT, avg_rating NUMERIC) AS
$$
DECLARE
	pt DATE := make_date(y, m, 1);
	next_month DATE;
BEGIN
	IF m = 12 THEN
		next_month := make_date(y+1, 1, 1);
	ELSE
		next_month := make_date(y, m+1, 1);
	END IF;

	RETURN QUERY(
		SELECT S.pay_time, S.amount, S.pet_day, 
			(SELECT COUNT(*)
			FROM bids 
			WHERE ct_phone = _phone AND status = 'Success'
			AND start_date >= pt AND start_date < next_month) AS num_bids, 
			(SELECT AVG(rating)
			FROM bids 
			WHERE ct_phone = _phone AND status = 'Success'
			AND start_date >= pt AND start_date < next_month) AS avg_rating
		FROM salary S
		WHERE S.phone = _phone AND S.pay_time = pt
		);
END;
$$
LANGUAGE plpgsql;

/*
SELECT * FROM ct_view_bid_details()
*/

CREATE OR REPLACE FUNCTION ct_view_bid_details(_phone INTEGER, _pet_name VARCHAR)
	RETURNS TABLE (
		owner_name VARCHAR, phone INTEGER, pet_name VARCHAR, transfer_location VARCHAR,
		category VARCHAR, special_requirements VARCHAR(500)
		) AS
$$
BEGIN
	RETURN QUERY(
		SELECT P.name AS owner_name, P.phone, O.name AS pet_name, P.transfer_location,
			O.category_name AS category, O.special_requirements
		FROM owns_pet O, pet_owner P
		WHERE O.phone = _phone AND O.phone = P.phone AND O.name = _pet_name
		);
END;
$$
LANGUAGE plpgsql;

/*

CREATE OR REPLACE FUNCTION underperforming_fulltime(y INTEGER)
	RETURNS TABLE () AS
$$
DECLARE
BEGIN
END;
$$
LANGUAGE plpgsql;*/