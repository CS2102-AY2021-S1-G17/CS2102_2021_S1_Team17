/* initialise category*/
INSERT INTO category (category_name, base_price) 
			VALUES ('bird', 1), ('cat', 1), ('dog', 1);

/*create pending bids for testing purpose */
/*记得先在网页上注册：
po：0 （pet name 0）
full time ct： 1
*/

/*create pending bids for testing purpose */
/* CALL place_bid(0, 1, '0', '2020-12-01', '2020-12-10', 'via PCS', 'Cash');*/
/*CALL place_bid(0, 1, '0', '2021-1-01', '2021-11-10', 'via PCS', 'Cash');*/

/*create successful bids for testing purpose */
/* CALL change_bid_status(0, 1, '0','2021-1-01', '2021-11-10','Success'); */