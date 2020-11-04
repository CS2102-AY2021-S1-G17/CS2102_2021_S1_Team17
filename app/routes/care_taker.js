var express = require('express');
var db = require('../db');
var router = express.Router();

router.all("*", function (req, res, next) {
  if (!req.user) {
      return res.redirect("/");
  } else {
      next();
  }
});

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT category_name FROM capable WHERE phone=$1;",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM ct_view_pending_bids($1);",[req.user.phone]);
      var cat_list = [];
      var pending_bids = data3.rows; 
      for (let i = 0; i < data2.rows.length; i++) {
        Object.keys(data2.rows[i]).forEach(function(key) {
          cat_list.push(data2.rows[i][key])
        });
      }
      //console.log(pending_bids); contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('care_taker/ct_profile', { title: 'Caretaker Page', profile:data.rows[0], cat_list: cat_list, pending_bids:pending_bids});
    } catch (err) {
      throw err;
    }
});

/* GET Profile page. */ 
router.get('/profile',  async(req, res, next)=> {
  try{
    var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var data2 = await db.query("SELECT category_name FROM capable WHERE phone=$1;",[req.user.phone]);
    var data3 = await db.query("SELECT * FROM ct_view_pending_bids($1);",[req.user.phone]);
    var cat_list = [];
    var pending_bids = data3.rows; 
    for (let i = 0; i < data2.rows.length; i++) {
      Object.keys(data2.rows[i]).forEach(function(key) {
        cat_list.push(data2.rows[i][key])
      });
    }
    //console.log(pending_bids); contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
    res.render('care_taker/ct_profile', { title: 'Caretaker Page', profile:data.rows[0], cat_list: cat_list, pending_bids:pending_bids});
  } catch (err) {
    throw err;
  }
});

router.get('/salary',  async(req, res, next)=> {
  try {
    var salary_list = await db.query('SELECT * FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    res.render('care_taker/ct_salary', { title: 'Salary', user : req.user });
  } catch(err) {
    throw err;
  }
}); 

router.get('/availability',  function(req, res, next) {
      res.render('care_taker/ct_availability', { title: 'Availability Page', user : req.user });
}); 

router.get('/history',  function(req, res, next) {
  res.render('care_taker/ct_history', { title: 'History Page', user : req.user });
}); 

module.exports = router;