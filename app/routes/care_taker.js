var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    res.render('care_taker/ct_profile', { title: 'Caretaker Page'});
});

/* GET Profile page. */ 
router.get('/profile',  function(req, res, next) {
      res.render('care_taker/ct_profile', { title: 'Profile Page', user : req.user });
}); 

router.get('/profile_edit',  function(req, res, next) {
      res.render('care_taker/ct_profile_edit', { title: 'Edit Profile', user : req.user });
}); 

router.get('/availability',  function(req, res, next) {
      res.render('care_taker/ct_availability', { title: 'Availability Page', user : req.user });
}); 

module.exports = router;
