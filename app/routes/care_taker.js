var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    if (req.user) {
      res.render('caretaker', { title: 'Caretaker Page'});
    }
});

/* GET Profile page. */ 
router.get('/profile',  function(req, res, next) {
      res.render('profile', { title: 'Profile Page', user : req.user,
      avatar: gravatar.url(req.user.email ,  {s: '100', r: 'x', d:
      'retro'}, true) });
  }); 
module.exports = router;
