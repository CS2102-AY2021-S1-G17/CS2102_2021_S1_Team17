var express = require('express');
var db = require('../db');
var router = express.Router();

router.get('/', async(req, res, next)=> { 
  try{
    var data = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var data2 = await db.query("SELECT * FROM po_view_upcoming_bids($1)",[req.user.phone]);

    // variables
    var name = data.rows.name;
    var location = data.rows.transfer_location;
    var card = data.rows.card;
    var bid_list = data2.rows;

    //check features of rows
    console.log(bid_list);

    res.render('pet_owner/po_profile', { title: 'Pet Owner Page'});
  } catch (err) {
    throw err;
  }
});

router.get('/po_profile',  async(req, res, next)=> { 
  try{
    var data = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var data2 = await db.query("SELECT * FROM po_view_upcoming_bids($1)",[req.user.phone]);

    // variables
    var name = data.rows.name;
    var location = data.rows.transfer_location;
    var card = data.rows.card;
    var bid_list = data2.rows;

    //check features of rows
    console.log(bid_list);

    res.render('pet_owner/po_profile', { title: 'Pet Owner Page'});
  } catch (err) {
    throw err;
  }
}); 

router.get('/pets',  async(req, res, next)=> {
  try{
    var data = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var data2 = await db.query("SELECT * FROM po_view_pets($1)",[req.user.phone]);

    // variables
    var name = data.rows.name;
    var location = data.rows.transfer_location;
    var card = data.rows.card;
    var pet_list = data2.rows;

    //check features of rows
    console.log(pet_list);

    res.render('pet_owner/po_pets_profile', { title: 'Pet Owner Page' });
  } catch (err) {
    throw err;
  }  
}); 

router.get('/history',  async(req, res, next)=> {
  try {
    var data = await db.query("SELECT * FROM po_view_past_trans($1);",[req.user.phone]);
    // variables
    var past_bid_list = data.rows;

    //check features of rows
    console.log(past_bid_list);

    res.render('pet_owner/po_history', { title: 'Pet Owner Page' });
  } catch (err) {
    throw err;
  }
}); 

router.get('/bid',  async(req, res, next)=> {
  try{
    var data = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var data2 = await db.query("SELECT phone, name, transfer_location, is_full_time, avg_rating FROM care_taker");

    // variables
    var name = data.rows.name;
    var location = data.rows.transfer_location;
    var card = data.rows.card;
    // default show all ct, not the search
    var ct_list = data2.rows;

    //check features of rows
    console.log(ct_list);

    res.render('pet_owner/po_bid', { title: 'Pet Owner Page' });
  } catch (err) {
    throw err;
  }
}); 
module.exports = router;
