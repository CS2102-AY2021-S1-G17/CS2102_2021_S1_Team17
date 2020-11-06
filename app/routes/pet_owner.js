var express = require('express');
var db = require('../db');
const { route } = require('.');
var router = express.Router();

router.all("*", function (req, res, next) {
  if (!req.user || req.user.role != 'pet_owner') {
      return res.redirect("/");
  } else {
      next();
  }
});

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM po_view_upcoming_bids($1)",[req.user.phone]);
      var pending_bids = data3.rows; 
//      var future_work = data4.rows;　
//      for (let i = 0; i < data2.rows.length; i++) {
//        Object.keys(data2.rows[i]).forEach(function(key) {
//          cat_list.push(data2.rows[i][key])
//        });
      //}
      //console.log(future_work); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('pet_owner/po_profile', { title: 'Petowner Page', profile:data.rows[0], pending_bids:pending_bids});
    } catch (err) {
      throw err;
    }
});

router.get('/po_profile',  async(req, res, next)=> {
  try{
    var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
    var data3 = await db.query("SELECT * FROM po_view_upcoming_bids($1);",[req.user.phone]);
    var pending_bids = data3.rows;
    res.render('pet_owner/po_profile', { title: 'Petowner Page', profile:data.rows[0], pending_bids:pending_bids});
  } catch (err) {
    throw err;
  }
});

router.post('/update_location', async(req, res)=> {
  try{
    console.log(req.body);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/pet_owner");
  }
});

router.post('/pay', async(req, res)=> {
  try{
    console.log(req.body);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/pet_owner");
  }
});

router.get('/pets',  async(req, res, next) => {
    try{
        var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
        var data3 = await db.query("SELECT * FROM po_view_upcoming_bids($1);",[req.user.phone]);
        var pending_bids = data3.rows;
        res.render('pet_owner/po_pets_profile', { title: 'PetOwner Page', profile:data.rows[0], pending_bids:pending_bids});
    } catch (err) {
        throw err;
    }
}); 

router.get('/history', async(req, res, next)=> {
  var data3 = await db.query("SELECT * FROM po_view_past_trans($1);",[req.user.phone]);
  console.log(data3.rows);
  res.render('pet_owner/po_history', { title: 'History Page', history: data3.rows});
});

router.get('/bid',  function(req, res, next) {
      res.render('pet_owner/po_bid', { title: 'Bid Page', user : req.user });
}); 

router.get('/search',  function(req, res, next) {
      res.render('pet_owner/po_bid', { title: 'Bid Page', user : req.user });
}); 
module.exports = router;
