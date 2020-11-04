var express = require('express');
var router = express.Router();

router.get('/', async(req, res, next)=> { 
  try{
    var po_info = await db.query("SELECT * FROM pet_owner WHERE phone=$1;",[req.user.phone]);
    var name = data.rows.name;
    res.render('pet_owner/po_profile', { title: 'Petowner Page'});
  } catch (err) {
    throw err;
  }
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

router.get('/bid',  function(req, res, next) {
      res.render('pet_owner/po_bid', { title: 'Bid Page', user : req.user });
}); 
module.exports = router;
