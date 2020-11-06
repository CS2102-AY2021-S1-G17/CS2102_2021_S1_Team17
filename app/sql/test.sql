/* initialise category*/
INSERT INTO category (category_name, base_price) 
			VALUES ('bird', 1), ('cat', 1), ('dog', 1);

/*create bids for testing purpose */
/*记得先在网页上注册：
po：0 （pet name 0）
full time ct： 1
*/
-- CALL place_bid(2, 1, '2', '2020-11-09', '2020-12-10', 'via PCS', 'Cash');
INSERT INTO users VALUES(8,'$2b$10$SoUWO2aoWqDjIea7ro9VJuhqeBPxXMoBTG4XuEjZJMr1ijS9rtRnm','Admin');
INSERT INTO admin VALUES (8,'$2b$10$SoUWO2aoWqDjIea7ro9VJuhqeBPxXMoBTG4XuEjZJMr1ijS9rtRnm',8);
