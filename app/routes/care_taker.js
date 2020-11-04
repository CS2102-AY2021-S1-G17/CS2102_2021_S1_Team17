var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    res.render('care_taker/ct_profile', { title: 'Home Page'});
});

/* GET Profile page. */ 
router.get('/profile',  function(req, res, next) {
      res.render('care_taker/ct_profile', { title: 'Profile', user : req.user });
}); 

router.get('/salary',  function(req, res, next) {
      res.render('care_taker/ct_salary', { title: 'Salary', user : req.user });
}); 

router.get('/availability',  function(req, res, next) {
      res.render('care_taker/ct_availability', { title: 'Availability', user : req.user });
}); 
router.get('/history',  function(req, res, next) {
      res.render('care_taker/ct_history', { title: 'Hisotry', user : req.user });
}); 

module.exports = router;
