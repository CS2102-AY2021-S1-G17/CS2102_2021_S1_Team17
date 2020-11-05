var express = require('express');
var db = require('../db');
var router = express.Router();

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT category_name FROM capable WHERE phone=$1;",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM ct_view_pending_bids($1);",[req.user.phone]);
      // variables
      var name = data.rows.name;
      if (data.rows.is_full_time) {
        var full_part = "Full Time Employee";
      } else {
        var full_part = "Part Time Employee";
      }
      var rate = data.rows.avg_rating;
      var cat_list = data2.rows;
      var pending_bids = data3.rows; //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]

      console.log(pending_bids);
      
      res.render('care_taker/ct_profile', { title: 'Caretaker Page'});
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
    var name = data.rows.name;
    if (data.rows.is_full_time) {
      var full_part = "Full Time Employee";
    } else {
      var full_part = "Part Time Employee";
    }
    var rate = data.rows.avg_rating;
    var cat_list = data2.rows;
    var pending_bids = data3.rows; //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
    console.log(pending_bids);
    res.render('care_taker/ct_profile', { title: 'Caretaker Page'});
  } catch (err) {
    throw err;
  }
});

router.get('/salary',  async(req, res, next)=> {
  try {
    var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var data1 = await db.query('SELECT * FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    // variables
    var name = data.rows.name;
    if (data.rows.is_full_time) {
      var full_part = "Full Time Employee";
    } else {
      var full_part = "Part Time Employee";
    }
    var salary_list = data1.rows;
    
    //check features of rows
    console.log(salary_list);

    res.render('care_taker/ct_salary', { title: 'Salary'});
  } catch(err) {
    throw err;
  }
}); 

router.get('/availability',  async(req, res)=> {
  try {
    var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var data1 = await db.query('SELECT * FROM ct_view_future_work($1);', [req.user.phone]);
    // variables
    var name = data.rows.name;
    if (data.rows.is_full_time) {
      var full_part = "Full Time Employee";
    } else {
      var full_part = "Part Time Employee";
    }
    var feture_work_list = data1.rows;
    // daily????
    //for (var d = new Date(2012, 0, 1); d <= now; d.setDate(d.getDate() + 1)) {
    //  daysOfYear.push(new Date(d));
    //}

    //check features of rows
    console.log(feture_work_list);
    
    res.render('care_taker/ct_availability', { title: 'Availability Page'});
  } catch(err) {
    throw err;
  }
}); 

//==================Apply Leave========================
router.post("/availability", async(req, res) =>{
    let daterangepicker = req.body;
    console.log(daterangepicker);
    console.log(1);
    try {
      console.log(2);
      console.log(daterangepicker);
      //await
    } catch(err) {
      req.flash("error", "Leave application failed.");
    } finally {
      res.redirect("/care_taker/availability");
    }
});

module.exports = router;
