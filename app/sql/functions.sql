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
	_email VARCHAR,
	_password VARCHAR,
	_name VARCHAR
	) AS
$$
BEGIN
	INSERT INTO admin (email, password, name)
		VALUES (_email, _password, _name);
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
	SELECT P.category_name INTO _category FROM owns_pet P WHERE P.phone = _po_phone AND P.name = _pet_name;
	SELECT C.daily_price INTO _daily_price FROM capable C WHERE C.phone = _ct_phone AND C.category_name = _category;
	_total_cost = _daily_price * (_end_date - _start_date + 1);
	INSERT INTO bids (po_phone, ct_phone, pet_name, start_date, end_date, 
		status, category_name, daily_price, transfer_method, total_cost, payment_method, rating, comment)
		VALUES (_po_phone, _ct_phone, _pet_name, _start_date, _end_date, 
		'pending', _category, _daily_price, _transfer_method, _total_cost, _payment_method, NULL, NULL);
END;
$$
LANGUAGE plpgsql;

/**/









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
			IF curr_m > m THEN
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
