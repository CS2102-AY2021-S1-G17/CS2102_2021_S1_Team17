var express = require('express');
var db = require('../db');
var router = express.Router();

router.get('/', async(req, res, next)=> { 
  try{
    var po_info = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var bids_info = await db.query("SELECT * FROM bids WHERE po_phone=$1",[req.user.phone]);
    var name = po_info.rows[0].name;
    res.render('pet_owner/po_profile', { title: name+"'s Page", user : req.user });
  } catch (err) {
    throw err;
  }
});

router.get('/po_profile',  async(req, res, next)=> { 
  try{
    var po_info = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var bids_info = await db.query("SELECT * FROM bids WHERE po_phone=$1;",[req.user.phone]);
    res.render('pet_owner/po_profile', { title: req.user.name+"'s Page", user : req.user });
  } catch (err) {
    throw err;
  }
}); 

router.get('/pets',  async(req, res, next)=> {
  try {
    var pets_info = await db.query("SELECT po_view_pets($1);",[req.user.phone]);
    console.log(pets_info);
    res.render('pet_owner/po_pets_profile', { title: req.user.name+"'s Page", user : req.user });
  } catch (err) {
    throw err;
  }  
}); 

router.get('/history',  async(req, res, next)=> {
  try {
    var trans_info = await db.query("SELECT po_view_past_trans($1);",[req.user.phone]);
    console.log(trans_info);
    res.render('pet_owner/po_history', { title: req.user.name+"'s History Transaction Page", user : req.user });
  } catch (err) {
    throw err;
  }
}); 

router.get('/bid',  async(req, res, next)=> {
      res.render('pet_owner/po_bid', { title: req.user.name+"'s Bid Page", user : req.user });
}); 
module.exports = router;
