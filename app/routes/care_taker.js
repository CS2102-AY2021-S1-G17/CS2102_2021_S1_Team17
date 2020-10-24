var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    if (req.user) {
      res.render('caretaker', { title: 'Caretaker Page'});
    }
});

module.exports = router;
