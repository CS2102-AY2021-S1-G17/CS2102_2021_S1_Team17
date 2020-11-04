var express = require('express');
var db = require('../db');
var router = express.Router();

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT category_name FROM capable WHERE phone=$1;",[req.user.phone]);
      var name = data.rows.name;
      if (data.rows.is_full_time) {
        var full_part = "Full Time Employee";
      } else {
        var full_part = "Part Time Employee";
      }
      var rate = data.rows.avg_rating;
      
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
    var name = data.rows.name;
    if (data.rows.is_full_time) {
      var full_part = "Full Time Employee";
    } else {
      var full_part = "Part Time Employee";
    }
    var rate = data.rows.avg_rating;
    res.render('care_taker/ct_profile', { title: 'Profile Page'});
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

module.exports = router;
