var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    res.render('care_taker/ct_profile', { title: 'Caretaker Page'});
});

/* GET Profile page. */ 
router.get('/profile',  function(req, res, next) {
      res.render('care_taker/ct_profile', { title: 'Profile Page', user : req.user });
}); 

router.get('/salary',  function(req, res, next) {
      res.render('care_taker/ct_salary', { title: 'Salary', user : req.user });
}); 

router.get('/availability',  function(req, res, next) {
      res.render('care_taker/ct_availability', { title: 'Availability Page', user : req.user });
}); 

module.exports = router;
