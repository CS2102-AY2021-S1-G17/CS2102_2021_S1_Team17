/* initialise category*/
INSERT INTO category (category_name, base_price) 
			VALUES ('bird', 1), ('cat', 1), ('dog', 1);

/*create bids for testing purpose */
/*记得先在网页上注册：
po：0 （pet name 0）
full time ct： 1
*/
CALL place_bid(2, 1, '2', '2020-11-07', '2020-12-10', 'via PCS', 'Cash');