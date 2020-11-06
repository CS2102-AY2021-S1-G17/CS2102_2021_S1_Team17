var express = require('express');
var db = require('../db');
const { route } = require('.');
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
      var data3 = await db.query("SELECT * FROM ct_view_pending_bids($1)",[req.user.phone]);
      var data4 = await db.query("SELECT * FROM ct_view_future_work($1)",[req.user.phone]);
      var cat_list = [];
      var pending_bids = data3.rows; 
      var future_work = data4.rows;　
      for (let i = 0; i < data2.rows.length; i++) {
        Object.keys(data2.rows[i]).forEach(function(key) {
          cat_list.push(data2.rows[i][key])
        });
      }
      //console.log(future_work); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('care_taker/ct_profile', { title: 'Caretaker Page', profile:data.rows[0], cat_list: cat_list, pending_bids:pending_bids, future_work: future_work});
    } catch (err) {
      throw err;
    }
});

/* Update caretaker category. */ 
router.post('/category', async(req, res)=> {
  try{
    let {po_phone, cat, dog, bird,} = req.body;
    console.log(cat);
    console.log(bird);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/care_taker");
  }
});

/* Update bid status. */ 
router.post('/update_status', async(req, res)=> {
  try{
    console.log(req.body);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/care_taker");
  }
});

/* Update availablity. */ 
router.post('/availability', async(req, res)=> {
  try{
    console.log(req.body);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/care_taker");
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
    var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var time = await db.query('SELECT pay_time FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    var salary = await db.query('SELECT amount FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    var time_list = [];
    var salary_list = [];
    for (let i = 0; i < time.rows.length; i++) {
        time_list.push(time.rows[i].pay_time);
    }
    for (let i = 0; i < salary.rows.length; i++) {
      salary_list.push(salary.rows[i].amount);
    } 
    res.render('care_taker/ct_salary', { title: 'Salary', salary:salary_list, time:time_list, profile:data.rows[0] });
  } catch(err) {
    throw err;
  }
}); 

router.get('/history', async(req, res, next)=> {
  var data3 = await db.query("SELECT * FROM ct_view_past_trans($1);",[req.user.phone]);
  console.log(data3.rows);
  res.render('care_taker/ct_history', { title: 'History Page', history: data3.rows});
}); 

module.exports = router;