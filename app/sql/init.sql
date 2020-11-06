-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- CREATE TABLE --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS pet_owner CASCADE;
DROP TABLE IF EXISTS care_taker CASCADE;
DROP TABLE IF EXISTS admin CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS owns_pet CASCADE;
DROP TABLE IF EXISTS availability CASCADE;
DROP TABLE IF EXISTS capable CASCADE;
DROP TABLE IF EXISTS salary CASCADE;
DROP TABLE IF EXISTS pay CASCADE;
DROP TABLE IF EXISTS bids CASCADE;

CREATE TABLE users(
	phone INTEGER PRIMARY KEY,
	password VARCHAR NOT NULL,
	role VARCHAR NOT NULL CHECK(role IN ('Pet Owner', 'Caretaker', 'Both', 'Admin')),
	UNIQUE(phone, password)
);

CREATE TABLE pet_owner(
	phone INTEGER,
	password VARCHAR NOT NULL,
	transfer_location VARCHAR,
	name VARCHAR NOT NULL,	
	card VARCHAR(16),
	PRIMARY KEY(phone),
	FOREIGN KEY (phone, password) REFERENCES users(phone, password)
	ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE care_taker(
	phone INTEGER,
	password VARCHAR NOT NULL,
	transfer_location VARCHAR,
	name VARCHAR NOT NULL,
	bank_account VARCHAR NOT NULL,
	is_full_time BOOLEAN NOT NULL,
	avg_rating FLOAT8 DEFAULT 0 CHECK(avg_rating >= 0 AND avg_rating <= 5),
	care_limit INTEGER NOT NULL 
	CHECK(care_limit = CASE 
		WHEN is_full_time IS TRUE THEN 5
		WHEN is_full_time IS NOT TRUE AND avg_rating < 4 THEN 2 
		WHEN is_full_time IS NOT TRUE AND avg_rating >= 4 THEN 5
		END),
	PRIMARY KEY (phone),
	FOREIGN KEY (phone, password) REFERENCES users(phone, password)
	ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE admin(
	phone INTEGER PRIMARY KEY,
	password VARCHAR NOT NULL,
	name VARCHAR NOT NULL,
	FOREIGN KEY (phone, password) REFERENCES users(phone, password)
	ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE category(
	category_name VARCHAR PRIMARY KEY,
	base_price FLOAT8 NOT NULL
);

CREATE TABLE owns_pet(
	phone INTEGER NOT NULL REFERENCES pet_owner(phone) ON DELETE CASCADE ON UPDATE CASCADE,
	name VARCHAR,
	special_requirements VARCHAR(500),
	category_name VARCHAR NOT NULL REFERENCES category(category_name),
	PRIMARY KEY(phone, name),
	UNIQUE(phone, name, category_name)
);

CREATE TABLE availability(
	phone INTEGER REFERENCES care_taker(phone) ON DELETE CASCADE ON UPDATE CASCADE,
	available_date DATE,
	remaining_limit INTEGER CHECK(remaining_limit >= 0),
	PRIMARY KEY (phone, available_date),
	UNIQUE(phone, available_date)
);

CREATE TABLE capable(
	phone INTEGER REFERENCES care_taker(phone) ON DELETE CASCADE ON UPDATE CASCADE,
	category_name VARCHAR REFERENCES category(category_name),
	daily_price FLOAT8 NOT NULL,
	PRIMARY KEY(phone, category_name),
	UNIQUE(phone, category_name, daily_price)
);

CREATE TABLE salary(
	phone INTEGER REFERENCES care_taker(phone) ON DELETE CASCADE ON UPDATE CASCADE,
	pay_time DATE,
	amount FLOAT8 DEFAULT 0,
	pet_day INTEGER,
	PRIMARY KEY(phone, pay_time)
);

CREATE TABLE pay(
	ad_phone INTEGER NOT NULL REFERENCES admin(phone) ON DELETE CASCADE ON UPDATE CASCADE,
	ct_phone INTEGER,
	pay_time DATE, 
	PRIMARY KEY(ct_phone, pay_time),
	FOREIGN KEY (ct_phone, pay_time) REFERENCES salary(phone, pay_time)
	ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE bids(
	po_phone INTEGER,
	ct_phone INTEGER,
	pet_name VARCHAR,
	start_date DATE,
	end_date DATE CHECK(end_date >= start_date),
	
	-- pending = no decision made; 
	-- withdraw = by po; 
	-- accepted / rejected = by ct; 
	-- success / fail = transaction status
	status VARCHAR NOT NULL DEFAULT 'Pending'
	CHECK(status IN ('Pending', 'Withdraw', 'Rejected', 'Accepted', 'Success', 'Fail')),
	category_name VARCHAR NOT NULL,
	daily_price FLOAT8 NOT NULL,
	transfer_method VARCHAR NOT NULL CHECK(transfer_method IN ('PO deliver', 'CT pick up', 'via PCS')),
	total_cost FLOAT8 NOT NULL CHECK (total_cost = daily_price * (end_date - start_date + 1)),
	payment_method VARCHAR NOT NULL CHECK(payment_method IN ('Cash', 'Credit Card')),
	rating INTEGER CHECK(rating >= 1 and rating <= 5),
	comment VARCHAR(500),

	PRIMARY KEY (po_phone, ct_phone, pet_name, start_date, end_date),
	FOREIGN KEY (po_phone, pet_name, category_name) REFERENCES owns_pet(phone, name, category_name)
	ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ct_phone, category_name) REFERENCES capable(phone, category_name)
	ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ct_phone, start_date) REFERENCES availability(phone, available_date)
	ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ct_phone, end_date) REFERENCES availability(phone, available_date)
	ON DELETE CASCADE ON UPDATE CASCADE
);

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- CT TRIGGERS --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS update_ratelimit_dailyprice ON care_taker;
DROP TRIGGER IF EXISTS init_salary_availability ON care_taker;

/* 
Given an update on caretaker, check if rating and limit have been changed, 
if yes, update correspondingly on capable and availability
*/

CREATE OR REPLACE FUNCTION update_ratelimit_dailyprice() RETURNS TRIGGER AS
$update_ratelimit_dailyprice$
DECLARE
	cat VARCHAR;
	dif INTEGER;
	day DATE;
BEGIN
	IF OLD.avg_rating != NEW.avg_rating AND NEW.is_full_time THEN
		FOR cat IN (SELECT category_name FROM capable WHERE phone = NEW.phone) LOOP
			UPDATE capable 
				SET daily_price = 
					(CASE 
						WHEN NEW.avg_rating >= 4 
						THEN (SELECT base_price FROM category WHERE category_name = cat) + 10 * (NEW.avg_rating - 4)
						WHEN NEW.avg_rating < 4 
						THEN (SELECT base_price FROM category WHERE category_name = cat)
					END)
				WHERE capable.phone = NEW.phone AND capable.category_name = cat;
		END LOOP;
	END IF;
	IF NEW.care_limit != OLD.care_limit THEN
		dif := NEW.care_limit - OLD.care_limit;
		FOR day IN (
			SELECT A.available_date 
			FROM availability A 
			WHERE A.phone = NEW.phone AND A.available_date > CURRENT_DATE
			) LOOP
			UPDATE availability 
				SET remaining_limit = (CASE WHEN remaining_limit + dif >= 0 THEN remaining_limit + dif ELSE 0 END)
				WHERE availability.phone = NEW.phone AND availability.available_date = day;
		END LOOP;
	END IF;
	RETURN NEW;
END;
$update_ratelimit_dailyprice$
LANGUAGE plpgsql;

CREATE TRIGGER update_ratelimit_dailyprice 
	AFTER UPDATE ON care_taker
	FOR EACH ROW
	WHEN (OLD.avg_rating IS DISTINCT FROM NEW.avg_rating OR OLD.care_limit IS DISTINCT FROM NEW.care_limit)
	EXECUTE PROCEDURE update_ratelimit_dailyprice();

/*
Given a newly inserted caretaker, 
initialize his/her salary and availability for current and next year
*/

CREATE OR REPLACE FUNCTION init_salary_availability() RETURNS TRIGGER AS
$init_salary_availability$
DECLARE 
	y INTEGER;
	m INTEGER;
	curr_m INTEGER;
	pt DATE;
	d DATE;
	ed DATE;
BEGIN
	y := date_part('year', (SELECT CURRENT_TIMESTAMP));
	m := date_part('month', (SELECT CURRENT_TIMESTAMP));
	curr_m := m;
	pt := make_date(y, m, 1);
	d := CURRENT_DATE;
	ed := make_date(y+1, 12, 31); -- end of next year

	IF NEW.is_full_time THEN
		INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (NEW.phone, pt, 3000, 0);
		WHILE d <= ed LOOP
			m := date_part('month', d);
			IF m != curr_m THEN
				INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (NEW.phone, d, 3000, 0);
				curr_m := m;
			END IF;
			INSERT INTO availability (phone, available_date, remaining_limit) VALUES (NEW.phone, d, 5);
			d := d + INTEGER '1';
		END LOOP;
	ELSE 
		INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (NEW.phone, pt, 0, NULL);
	END IF;

	RETURN NEW;
END;
$init_salary_availability$
LANGUAGE plpgsql;

CREATE TRIGGER init_salary_availability 
	AFTER INSERT ON care_taker
	FOR EACH ROW
	EXECUTE PROCEDURE init_salary_availability();

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- CAPABLE TRIGGERS --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS check_daily_price ON capable;

/*
Before inserting or updating on capable, 
check that full time caretaker has correct daily price according to base price and rating,
if rating > 4, price = base + 10 * (rating - 4); if rating <= 4, price = base.

If daily price is incorrect, the function will halt procedure and return an error message.
*/

CREATE OR REPLACE FUNCTION check_daily_price() RETURNS TRIGGER AS
$check_daily_price$
DECLARE
	ft BOOLEAN;
	rt FLOAT8;
	name VARCHAR;
	bp FLOAT8;
BEGIN
	SELECT C.is_full_time, C.avg_rating, C.name INTO ft, rt, name 
		FROM care_taker C WHERE NEW.phone = C.phone;
	SELECT G.base_price INTO bp 
		FROM category G WHERE G.category_name = NEW.category_name;
	IF ft THEN
		IF rt <= 4 AND NEW.daily_price != bp THEN
			Raise Notice 'Caretaker % has incorrect daily price on category %', name, NEW.category_name;
			RETURN NULL;
		END IF;
		IF rt > 4 AND NEW.daily_price != bp + 10 * (rt - 4) THEN
			Raise Notice 'Caretaker % has incorrect daily price on category %', name, NEW.category_name;
			RETURN NULL;
		END IF;
	END IF;
	RETURN NEW;
END;
$check_daily_price$
LANGUAGE plpgsql;

CREATE TRIGGER check_daily_price
	BEFORE INSERT OR UPDATE ON capable
	FOR EACH ROW
	EXECUTE PROCEDURE check_daily_price();

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- AVAIL TRIGGERS --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS work_cleared_before_delete ON availability;
DROP TRIGGER IF EXISTS check_minimum_requirement ON availability;
DROP TRIGGER IF EXISTS check_bids_after_takeleave ON availability;
DROP TRIGGER IF EXISTS check_bids_no_limit ON availability;

/*
Before a caretaker is removing an entry from availability, aka take leave,
check that he/she has no unfinished job on that day.
*/

CREATE OR REPLACE FUNCTION work_cleared_before_delete() RETURNS TRIGGER AS
$work_cleared_before_delete$
DECLARE
	max_limit INTEGER;
BEGIN
	SELECT care_limit INTO max_limit FROM care_taker WHERE OLD.phone = phone;
    IF OLD.remaining_limit != max_limit THEN
        Raise Notice 'This caretaker has unfinished job on %', OLD.available_date;
        RETURN NULL;
    END IF;
    RETURN OLD;
END;
$work_cleared_before_delete$
LANGUAGE plpgsql;

CREATE TRIGGER work_cleared_before_delete 
	BEFORE DELETE ON availability
	FOR EACH ROW 
	EXECUTE PROCEDURE work_cleared_before_delete();

/*
Before deleting an entry from availability, aka take leave,
a full time caretaker has to satisfy a minumum requirement of 2*150 consecutive working days
and taking leave cannot violate this requirement. 
*/

CREATE OR REPLACE FUNCTION check_minimum_requirement() RETURNS TRIGGER AS
$check_minimum_requirement$
DECLARE
    ft BOOLEAN;
    day DATE;
    y INTEGER;
    previous_date DATE;
    end_date DATE;
    total_cnt INTEGER := 0;
    consecutive_cnt INTEGER := 0;
BEGIN
    SELECT C.is_full_time INTO ft FROM care_taker C WHERE OLD.phone = C.phone;
    IF ft IS NOT TRUE THEN
        RETURN OLD;
    END IF;
    y := date_part('year', OLD.available_date);
	previous_date := make_date(y, 1, 1);
	end_date := make_date(y, 12, 31);
    FOR day IN (
    	SELECT available_date 
    	FROM availability 
    	WHERE available_date != OLD.available_date AND phone = OLD.phone
    	AND available_date >= previous_date AND available_date <= end_date
    	) LOOP
        IF day - previous_date > 1 THEN
        	-- not consecutive with previous available date
            consecutive_cnt := 0;
        ELSE
        	-- consecutive with previous available date
            consecutive_cnt := consecutive_cnt + 1;
        END IF;
        previous_date := day;
        IF consecutive_cnt >= 150 THEN
        	-- meet one 150 consecutive days requirement
            total_cnt := total_cnt + 1;
            -- reset consecutive cnt for next round of 150 days
            consecutive_cnt := consecutive_cnt - 150;
        END IF;
    END LOOP;
    IF total_cnt >= 2 THEN
        RETURN OLD;
    ELSE
    	Raise Notice 'The caretaker does not meet the 2*150 consecutive working days requirement';
        RETURN NULL;
    END IF;
END;
$check_minimum_requirement$
LANGUAGE plpgsql;

CREATE TRIGGER check_minimum_requirement 
	BEFORE DELETE ON availability 
	FOR EACH ROW 
	EXECUTE PROCEDURE check_minimum_requirement();

/*
Before a caretaker takes leave, 
reject all pending / accepted bids on that date
*/

CREATE OR REPLACE FUNCTION check_bids_after_takeleave() RETURNS TRIGGER AS
$check_bids_after_takeleave$
DECLARE
	po_phone INTEGER;
	pet_name VARCHAR;
	start_date DATE;
	end_date DATE;
BEGIN
	-- pending = no decision made; 
	-- withdraw = by po; 
	-- accepted / rejected = by ct; 
	-- success / fail = transaction status
	FOR po_phone, pet_name, start_date, end_date IN (
		SELECT B.po_phone, B.pet_name, B.start_date, B.end_date
		FROM bids B 
		WHERE B.ct_phone = OLD.phone AND B.status IN ('Pending', 'Accepted')
		AND B.start_date <= OLD.available_date AND B.end_date >= OLD.available_date
		) LOOP
		UPDATE bids B
			SET B.status = 'Rejected'
			WHERE B.ct_phone = OLD.phone AND B.po_phone = po_phone AND B.pet_name = pet_name
			AND B.start_date = start_date AND B.end_date = end_date;
	END LOOP;
	RETURN OLD;
END;
$check_bids_after_takeleave$
LANGUAGE plpgsql;

CREATE TRIGGER check_bids_after_takeleave
	BEFORE DELETE ON availability 
	FOR EACH ROW 
	EXECUTE PROCEDURE check_bids_after_takeleave();

/*
After an update on availability, if remaining limit on that day is 0, 
reject all pending / accepted bids on that day
*/

CREATE OR REPLACE FUNCTION check_bids_no_limit() RETURNS TRIGGER AS
$check_bids_no_limit$
DECLARE
	po_phone INTEGER;
	pet_name VARCHAR;
	start_date DATE;
	end_date DATE;
BEGIN
	-- pending = no decision made; 
	-- withdraw = by po; 
	-- accepted / rejected = by ct; 
	-- success / fail = transaction status
	FOR po_phone, pet_name, start_date, end_date IN (
		SELECT B.po_phone, B.pet_name, B.start_date, B.end_date
		FROM bids B 
		WHERE B.ct_phone = NEW.phone AND B.status IN ('Pending', 'Accepted')
		AND B.start_date <= NEW.available_date AND B.end_date >= NEW.available_date
		) LOOP
		UPDATE bids B
			SET B.status = 'Rejected'
			WHERE B.ct_phone = NEW.phone AND B.po_phone = po_phone AND B.pet_name = pet_name
			AND B.start_date = start_date AND B.end_date = end_date;
	END LOOP;
	RETURN NEW;
END;
$check_bids_no_limit$
LANGUAGE plpgsql;

CREATE TRIGGER check_bids_no_limit
	AFTER UPDATE ON availability 
	FOR EACH ROW
	WHEN (NEW.remaining_limit = 0)
	EXECUTE PROCEDURE check_bids_no_limit();

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- BIDS TRIGGERS --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS bids_capable_check ON bids;
DROP TRIGGER IF EXISTS bids_availability_check ON bids;
DROP TRIGGER IF EXISTS bids_time_check ON bids;
DROP TRIGGER IF EXISTS update_avail_upon_success_bid ON bids;
DROP TRIGGER IF EXISTS update_avg_rating_limit ON bids;
DROP TRIGGER IF EXISTS update_salary_upon_success_bid ON bids;
DROP TRIGGER IF EXISTS autocharge_accepted_bids ON bids;
DROP TRIGGER IF EXISTS check_payment_method ON bids;
DROP TRIGGER IF EXISTS auto_accept_fulltime ON bids;

/*
Before placing a bid, check that caretaker is capable of taking care of pet
and that daily price is the same as in capable
*/

CREATE OR REPLACE FUNCTION bids_capable_check() RETURNS TRIGGER AS
$bids_capable_check$
BEGIN
	IF NEW.category_name NOT IN (SELECT category_name FROM capable WHERE phone = NEW.ct_phone) THEN
		Raise Notice 'This caretaker is not capable of taking care of %', NEW.category_name;
		RETURN NULL;
	ELSIF NEW.daily_price NOT IN (
		SELECT daily_price 
		FROM capable 
		WHERE phone = NEW.ct_phone AND category_name = NEW.category_name
		) THEN
		Raise Notice 'The daily price of this bid is incorrectly input';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$bids_capable_check$
LANGUAGE plpgsql;

CREATE TRIGGER bids_capable_check 
	BEFORE INSERT ON bids
	FOR EACH ROW 
	EXECUTE PROCEDURE bids_capable_check();

/*
Before placing a bid, check that caretaker can work on the day
*/

CREATE OR REPLACE FUNCTION bids_availability_check() RETURNS TRIGGER AS
$bids_availability_check$
DECLARE
	day DATE := NEW.start_date;
BEGIN
	IF NEW.start_date - CURRENT_DATE < 3 THEN
		Raise Notice 'You must place a bid at least 3 days in advance';
		RETURN NULL;
	END IF;
	WHILE (day <= NEW.end_date) LOOP
		IF day NOT IN (
			SELECT A.available_date
			FROM availability A 
			WHERE A.phone = NEW.ct_phone
			) OR 0 IN (
			SELECT A.remaining_limit 
			FROM availability A 
			WHERE A.phone = NEW.ct_phone AND A.available_date = day
			) THEN
			Raise Notice 'This caretaker is not free on %', day;
			RETURN NULL;
		END IF;
		day := day + INTEGER '1';
	END LOOP;
	RETURN NEW;
END;
$bids_availability_check$
LANGUAGE plpgsql;

CREATE TRIGGER bids_availability_check 
	BEFORE INSERT ON bids
	FOR EACH ROW 
	EXECUTE PROCEDURE bids_availability_check();

/*
Check that ct must accept bids 2 days in advance
Check that po must pay 1 day in advance
*/

CREATE OR REPLACE FUNCTION bids_time_check() RETURNS TRIGGER AS
$bids_time_check$
BEGIN
	IF NEW.status = 'Accepted' AND NEW.start_date - CURRENT_DATE < 2 THEN
		Raise Notice 'You must accept a bid at least 2 days in advance';
		RETURN NULL;
	ELSIF NEW.status = 'Success' AND NEW.start_date - CURRENT_DATE < 1 THEN
		Raise Notice 'You must pay for a bid at least 1 day in advance';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$bids_time_check$
LANGUAGE plpgsql;

CREATE TRIGGER bids_time_check
	BEFORE UPDATE ON bids
	FOR EACH ROW
	WHEN (NEW.status != OLD.status)
	EXECUTE PROCEDURE bids_time_check();

/*
After a bid has been placed successfully, aka status = 'Success',
the remaining limit of caretaker from start to end date is reduced by 1
*/

CREATE OR REPLACE FUNCTION update_avail_upon_success_bid() RETURNS TRIGGER AS
$update_avail_upon_success_bid$
DECLARE
	rl INTEGER;
	day DATE := NEW.start_date;
BEGIN
	WHILE day <= NEW.end_date LOOP
		UPDATE availability
			SET remaining_limit = remaining_limit - 1
			WHERE phone = NEW.ct_phone AND available_date = day;
		day := day + INTEGER '1';
	END LOOP;
	RETURN NEW;
END;
$update_avail_upon_success_bid$
LANGUAGE plpgsql;

CREATE TRIGGER update_avail_upon_success_bid 
	AFTER UPDATE ON bids
	FOR EACH ROW 
	WHEN (NEW.status = 'Success' AND OLD.status != 'Success')
	EXECUTE PROCEDURE update_avail_upon_success_bid();

/*
When there is a new rating, 
update the average rating, care limit of caretaker correspondingly
*/

CREATE OR REPLACE FUNCTION update_avg_rating_limit() RETURNS TRIGGER AS
$update_avg_rating_limit$
DECLARE
	avg_rt NUMERIC;
	ft BOOLEAN;
	cat VARCHAR;
	bp FLOAT8;
BEGIN
	SELECT AVG(B.rating) INTO avg_rt FROM bids B WHERE B.ct_phone = NEW.ct_phone;
	SELECT C.is_full_time INTO ft FROM care_taker C WHERE C.phone = NEW.ct_phone;

	IF ft IS NOT TRUE AND avg_rt < 4 THEN
		UPDATE care_taker
			SET care_limit = 2, avg_rating = avg_rt
			WHERE C.phone = NEW.ct_phone;
	ELSIF ft IS NOT TRUE AND avg_rt >= 4 THEN
		UPDATE care_taker
			SET care_limit = 5, avg_rating = avg_rt
			WHERE phone = NEW.ct_phone;
	ELSE
		UPDATE care_taker
			SET avg_rating = avg_rt
			WHERE phone = NEW.ct_phone;
	END IF;
	RETURN NEW;
END;
$update_avg_rating_limit$
LANGUAGE plpgsql;

CREATE TRIGGER update_avg_rating_limit
	AFTER UPDATE ON bids
	FOR EACH ROW 
	WHEN (NEW.rating IS NOT NULL)
	EXECUTE PROCEDURE update_avg_rating_limit();

/*
After a bid has been placed successfully, aka status = 'Success',
the salary of caretaker increases correspondingly
*/

CREATE OR REPLACE FUNCTION update_salary_upon_success_bid() RETURNS TRIGGER AS
$update_salary_upon_success_bid$
DECLARE
	y INTEGER;
	m INTEGER;
	pt DATE;
	ft BOOLEAN;
	pd INTEGER;
	dif INTEGER;
BEGIN
	y := date_part('year', NEW.start_date);
	m := date_part('month', NEW.start_date);
	pt := make_date(y, m, 1);
	SELECT C.is_full_time INTO ft FROM care_taker C WHERE C.phone = NEW.ct_phone;
	SELECT S.pet_day INTO pd FROM salary S WHERE S.phone = NEW.ct_phone AND S.pay_time = pt;
	-- if salary has not been initialized
	IF pt NOT IN (SELECT S.pay_time FROM salary S WHERE S.phone = NEW.ct_phone AND S.pay_time = pt) THEN
		IF ft IS NOT TRUE THEN
			INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (NEW.ct_phone, pt, 0, NULL);
		ELSE
			INSERT INTO salary (phone, pay_time, amount, pet_day) VALUES (NEW.ct_phone, pt, 3000, 0);
		END IF;
	END IF;
	
	IF ft AND pd < 60 THEN
		dif := 60 - pd;
		IF (NEW.end_date - NEW.start_date + 1) < dif THEN
			UPDATE salary
				SET pet_day = pet_day + (NEW.end_date - NEW.start_date + 1)
				WHERE phone = NEW.ct_phone AND pay_time = pt;
		ELSE
			UPDATE salary
				SET pet_day = 60, 
					amount = amount + 0.8 * (NEW.end_date - NEW.start_date + 1 - dif) * NEW.daily_price
				WHERE phone = NEW.ct_phone AND pay_time = pt;
		END IF;
	ELSIF ft AND pd >= 60 THEN
		UPDATE salary
			SET amount = amount + 0.8 * NEW.total_cost
			WHERE phone = NEW.ct_phone AND pay_time = pt;
	ELSE
		UPDATE salary
			SET amount = amount + 0.75 * NEW.total_cost
			WHERE phone = NEW.ct_phone AND pay_time = pt;
	END IF;
	RETURN NEW;
END;
$update_salary_upon_success_bid$
LANGUAGE plpgsql;

CREATE TRIGGER update_salary_upon_success_bid
	AFTER UPDATE ON bids
	FOR EACH ROW 
	WHEN (NEW.status = 'Success' AND OLD.status != 'Success')
	EXECUTE PROCEDURE update_salary_upon_success_bid();

/*
When a bid is been accepted, if the pet owner has a pre-registered credit card,
automatically pay for the bid and change the bid status to success
*/

CREATE OR REPLACE FUNCTION autocharge_accepted_bids() RETURNS TRIGGER AS
$autocharge_accepted_bids$
DECLARE
	card VARCHAR(16);
BEGIN
	SELECT P.card into card FROM pet_owner P WHERE P.phone = NEW.po_phone;
	IF card IS NOT NULL AND NEW.payment_method = 'Credit Card' THEN
		-- assume we can automatically charge him/her
		UPDATE bids
			SET status = 'Success'
			WHERE po_phone = NEW.po_phone AND ct_phone = NEW.ct_phone AND pet_name = NEW.pet_name
			AND start_date = NEW.start_date AND end_date = NEW.end_date;
	END IF;
	RETURN NEW;
END;
$autocharge_accepted_bids$
LANGUAGE plpgsql;

CREATE TRIGGER autocharge_accepted_bids
	AFTER UPDATE ON bids
	FOR EACH ROW 
	WHEN (NEW.status = 'Accepted')
	EXECUTE PROCEDURE autocharge_accepted_bids();

/*
Before placing a bid with payment method = credit card, 
check that the po has a credit card
*/

CREATE OR REPLACE FUNCTION check_payment_method() RETURNS TRIGGER AS
$check_payment_method$
DECLARE
	card VARCHAR(16);
	name VARCHAR;
BEGIN
	SELECT P.card, P.name into card, name FROM pet_owner P WHERE P.phone = NEW.po_phone;
	IF NEW.payment_method = 'Credit Card' AND card IS NULL THEN
		Raise Notice 'Pet Owner % does not have a credit card', name;
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$check_payment_method$
LANGUAGE plpgsql;

CREATE TRIGGER check_payment_method
	BEFORE INSERT ON bids
	FOR EACH ROW 
	EXECUTE PROCEDURE check_payment_method();

/*
Fulltime caretaker will auto accept a pending bid
*/

CREATE OR REPLACE FUNCTION auto_accept_fulltime() RETURNS TRIGGER AS
$auto_accept_fulltime$
DECLARE
	ft BOOLEAN;
BEGIN
	SELECT C.is_full_time INTO ft FROM care_taker C WHERE C.phone = NEW.ct_phone;
	IF ft THEN
		UPDATE bids
			SET status = 'Accepted'
			WHERE ct_phone = NEW.ct_phone AND po_phone = NEW.po_phone AND pet_name = NEW.pet_name
			AND start_date = NEW.start_date AND end_date = NEW.end_date;
	END IF;
	RETURN NEW;
END;
$auto_accept_fulltime$
LANGUAGE plpgsql;

CREATE TRIGGER auto_accept_fulltime
	AFTER INSERT ON bids
	FOR EACH ROW
	EXECUTE PROCEDURE auto_accept_fulltime();