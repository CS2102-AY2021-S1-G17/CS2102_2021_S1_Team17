var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    res.render('pet_owner/po_profile', { title: 'Petowner Page'});
});

router.get('/po_profile',  function(req, res, next) {
      res.render('pet_owner/po_profile', { title: 'Profile Page', user : req.user });
}); 

router.get('/pets',  function(req, res, next) {
      res.render('pet_owner/po_pets_profile', { title: 'Pets Profile Page', user : req.user });
}); 

router.get('/history',  function(req, res, next) {
      res.render('pet_owner/po_history', { title: 'History Transaction Page', user : req.user });
}); 
module.exports = router;
