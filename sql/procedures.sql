DROP PROCEDURE IF EXISTS register_pet_owner;
DROP PROCEDURE IF EXISTS register_caretaker;
DROP PROCEDURE IF EXISTS register_admin;
DROP PROCEDURE IF EXISTS place_bid;
DROP PROCEDURE IF EXISTS change_bid_status;
DROP PROCEDURE IF EXISTS rate_service;
DROP PROCEDURE IF EXISTS take_leave;
DROP PROCEDURE IF EXISTS claim_avail;
DROP PROCEDURE IF EXISTS add_pet;
DROP PROCEDURE IF EXISTS init_avail_salary_year;

/*
CALL register_pet_owner(...);
*/

CREATE OR REPLACE PROCEDURE register_pet_owner(
	_phone INTEGER,
	_password VARCHAR,
	_location VARCHAR,
	user_name VARCHAR,
	_card VARCHAR(16),
	pet_name VARCHAR,
	_requirements VARCHAR(500),
	_category VARCHAR
	) AS
$$
BEGIN
	IF 'Pet Owner' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		Raise Notice 'User has already registered as a pet owner';
	ELSIF 'Caretaker' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		-- If it's not the same password, insertion will fail here
		INSERT INTO pet_owner (phone, password, transfer_location, name, card) 
			VALUES (_phone, _password, _location, user_name, _card);
		INSERT INTO owns_pet (phone, name, special_requirements, category_name)
			VALUES (_phone, pet_name, _requirements, _category);
		UPDATE users
			SET role = 'Both'
			WHERE phone = _phone;
	ELSIF 'Admin' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		Raise Notice 'Do not use an admin account to register as pet owner';
	ELSE
		INSERT INTO users (phone, password, role)
			VALUES (_phone, _password, 'Pet Owner');
		INSERT INTO pet_owner (phone, password, transfer_location, name, card) 
			VALUES (_phone, _password, _location, user_name, _card);
		INSERT INTO owns_pet (phone, name, special_requirements, category_name)
			VALUES (_phone, pet_name, _requirements, _category);
	END IF;
END;
$$
LANGUAGE plpgsql;

/*
CALL register_caretaker(...);
*/

CREATE OR REPLACE PROCEDURE register_caretaker(
	_phone INTEGER,
	_password VARCHAR,
	_location VARCHAR,
	_name VARCHAR,
	_bank_account VARCHAR,
	_is_ft BOOLEAN,
	_category VARCHAR,
	_daily_price FLOAT8
	) AS
$$
DECLARE
	cl INTEGER;
	dp FLOAT8;
BEGIN
	IF _is_ft THEN
		cl := 5;
		SELECT C.base_price INTO dp FROM category C WHERE C.category_name = _category;
	ELSE
		cl := 2;
		dp := _daily_price;
	END IF;

	IF 'Caretaker' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		Raise Notice 'User has already registered as a caretaker';
	ELSIF 'Pet Owner' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		-- If it's not the same password, insertion will fail here
		INSERT INTO care_taker (phone, password, transfer_location, name, bank_account, is_full_time, avg_rating, care_limit)
			VALUES (_phone, _password, _location, _name, _bank_account, _is_ft, 0, cl);
		INSERT INTO capable (phone, category_name, daily_price)
			VALUES (_phone, _category, dp);
		UPDATE users
			SET role = 'Both'
			WHERE phone = _phone;
	ELSIF 'Admin' IN (SELECT U.role FROM users U WHERE U.phone = _phone) THEN
		Raise Notice 'Do not use an admin account to register as caretaker';
	ELSE
		INSERT INTO users (phone, password, role)
			VALUES (_phone, _password, 'Caretaker');
		INSERT INTO care_taker (phone, password, transfer_location, name, bank_account, is_full_time, avg_rating, care_limit)
			VALUES (_phone, _password, _location, _name, _bank_account, _is_ft, 0, cl);
		INSERT INTO capable (phone, category_name, daily_price)
			VALUES (_phone, _category, dp);
	END IF;
END;
$$
LANGUAGE plpgsql;

/*
CALL register_admin(...);
*/

CREATE OR REPLACE PROCEDURE register_admin(
	_phone INTEGER,
	_password VARCHAR,
	_name VARCHAR
	) AS
$$
BEGIN
	IF _phone IN (SELECT U.phone FROM users U WHERE U.phone = _phone) THEN
		Raise Notice 'Account already registered';
	END IF;
	-- If account already registered, insertion will fail here
	INSERT INTO users (phone, password, role)
		VALUES (_phone, _password, 'Admin');
	INSERT INTO admin (phone, password, name)
		VALUES (_phone, _password, _name);
END;
$$
LANGUAGE plpgsql;

/*
CALL place_bid(...);
*/

CREATE OR REPLACE PROCEDURE place_bid(
	_po_phone INTEGER,
	_ct_phone INTEGER,
	_pet_name VARCHAR,
	_start_date DATE,
	_end_date DATE,
	_transfer_method VARCHAR,
	_payment_method VARCHAR
	) AS
$$
DECLARE
	_category VARCHAR;
	_daily_price FLOAT8;
	_total_cost FLOAT8;
BEGIN
	IF _pet_name NOT IN (SELECT O.name FROM owns_pet O WHERE O.phone = _po_phone) THEN
		Raise Notice 'Pet does not belong to this owner';
	END IF;
	SELECT P.category_name INTO _category FROM owns_pet P WHERE P.phone = _po_phone AND P.name = _pet_name;
	SELECT C.daily_price INTO _daily_price FROM capable C WHERE C.phone = _ct_phone AND C.category_name = _category;
	_total_cost = _daily_price * (_end_date - _start_date + 1);
	INSERT INTO bids (po_phone, ct_phone, pet_name, start_date, end_date, 
		status, category_name, daily_price, transfer_method, total_cost, payment_method, rating, comment)
		VALUES (_po_phone, _ct_phone, _pet_name, _start_date, _end_date, 
		'Pending', _category, _daily_price, _transfer_method, _total_cost, _payment_method, NULL, NULL);
END;
$$
LANGUAGE plpgsql;

/*
CALL change_bid_status(...);
*/

CREATE OR REPLACE PROCEDURE change_bid_status(
	_po_phone INTEGER,
	_ct_phone INTEGER,
	_pet_name VARCHAR,
	_start_date DATE,
	_end_date DATE,
	_status VARCHAR
	) AS
$$
BEGIN
	UPDATE bids
		SET status = _status
		WHERE po_phone = _po_phone AND ct_phone = _ct_phone AND pet_name = _pet_name
		AND start_date = _start_date AND end_date = _end_date;
END;
$$
LANGUAGE plpgsql;

/*
CALL rate_service(...);
*/

CREATE OR REPLACE PROCEDURE rate_service(
	_po_phone INTEGER,
	_ct_phone INTEGER,
	_pet_name VARCHAR,
	_start_date DATE,
	_end_date DATE,
	_rating INTEGER,
	_comment VARCHAR(500)
	) AS
$$
DECLARE
	_status VARCHAR;
BEGIN
	SELECT status INTO _status
	FROM bids 
	WHERE po_phone = _po_phone AND ct_phone = _ct_phone AND pet_name = _pet_name 
	AND start_date = _start_date AND end_date = _end_date;

	IF _status != 'Success' THEN
		Raise Notice 'Unsuccessful transactions cannot be rated';
	ELSE
		UPDATE bids
			SET rating = _rating, comment = _comment
			WHERE po_phone = _po_phone AND ct_phone = _ct_phone AND pet_name = _pet_name 
			AND start_date = _start_date AND end_date = _end_date;
	END IF;
END;
$$
LANGUAGE plpgsql;

/*
CALL take_leave(...);
*/

CREATE OR REPLACE PROCEDURE take_leave(_phone INTEGER, _start DATE, _end DATE) AS
$$
BEGIN
	-- if avail triggers violated, deletion will fail with notice here
	DELETE FROM availability 
		WHERE phone = _phone AND available_date >= _start AND available_date <= _end;
END;
$$
LANGUAGE plpgsql;

/*
CALL claim_avail(...);
*/

CREATE OR REPLACE PROCEDURE claim_avail(_phone INTEGER, _start DATE, _end DATE) AS
$$
DECLARE
	day DATE := _start;
	rl INTEGER;
BEGIN
	SELECT C.care_limit INTO rl FROM care_taker C WHERE C.phone = _phone;
	WHILE day <= _end LOOP
		IF NOT EXISTS (SELECT * FROM availability A WHERE A.phone = _phone AND A.available_date = day) THEN
			INSERT INTO availability (phone, available_date, remaining_limit) VALUES (_phone, day, rl);
		END IF;
		day := day + INTEGER '1';
	END LOOP;
END;
$$
LANGUAGE plpgsql;

/*
CALL add_pet(...);
*/

CREATE OR REPLACE PROCEDURE add_pet(
	_phone INTEGER, pet_name VARCHAR, 
	_requirements VARCHAR(500), _category VARCHAR
	) AS
$$
BEGIN
	INSERT INTO owns_pet (phone, name, special_requirements, category_name)
		VALUES (_phone, pet_name, _requirements, _category);
END;
$$
LANGUAGE plpgsql;

/*
CALL add_capable(...);
*/

/*
CALL add_capable(...);
*/

CREATE OR REPLACE PROCEDURE add_capable(
	_phone INTEGER, _category VARCHAR, _daily_price FLOAT8
	) AS
$$
DECLARE
	avg_rt FLOAT8;
	bp FLOAT8;
	dp FLOAT8;
	ft BOOLEAN;
BEGIN
	SELECT is_full_time, avg_rating INTO ft, avg_rt FROM care_taker WHERE phone = _phone;
	SELECT base_price INTO bp FROM category WHERE category_name = _category;
	IF ft AND avg_rt > 4 THEN
		dp := bp + 10 * (avg_rt - 4);
	ELSIF ft AND avg_rt <= 4 THEN
		dp := bp;
	ELSE
		dp := _daily_price;
	END IF;
	IF _category IN (SELECT category_name FROM capable WHERE phone = _phone) THEN
		UPDATE capable
			SET daily_price = dp
			WHERE phone = _phone AND category_name = _category;
	ELSE
		INSERT INTO capable (phone, category_name, daily_price)
			VALUES (_phone, _category, dp);
	END IF;
END;
$$
LANGUAGE plpgsql;

/*
At the start of each year, call this procedure to 
initialize availability and salary for the specified year for full time caretakers.

CALL init_avail_salary_year(2019);
*/

CREATE OR REPLACE PROCEDURE init_avail_salary_year(y INTEGER) AS
$$
DECLARE
	m INTEGER := 0;
	curr_m INTEGER;
	d DATE;
	ed DATE;
	ct_phone INTEGER;
BEGIN
	ed := make_date(y, 12, 31);
	FOR ct_phone IN (SELECT C.phone FROM care_taker C WHERE C.is_full_time IS TRUE) LOOP
		d := make_date(y, 1, 1);
		WHILE d <= ed LOOP
			curr_m := date_part('month', d);
			IF curr_m > m AND d NOT IN (SELECT S.pay_time FROM salary S WHERE S.phone = ct_phone AND S.pay_time = d) THEN
				INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (ct_phone, d, 3000, 0);
				m := curr_m;
			END IF;
			IF d NOT IN (SELECT A.available_date FROM availability A WHERE A.phone = ct_phone AND A.available_date = d) THEN
				INSERT INTO availability (phone, available_date, remaining_limit) VALUES (ct_phone, d, 5);
			END IF;
			d := d + INTEGER '1';
		END LOOP;
	END LOOP;
END;
$$
LANGUAGE plpgsql;
