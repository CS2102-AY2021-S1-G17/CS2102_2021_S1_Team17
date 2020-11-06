var express = require('express');
var db = require('../db');
var router = express.Router();

router.get('/', async(req, res)=> { 
    try{
      //console.log(data.rows[0]); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('both/profile', { title: 'Caretaker Page', successFlash: req.flash("success"),
      errorFlash: req.flash("error")});
    } catch (err) {
      throw err;
    }
});

module.exports = router;