var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) { 
    res.render('petowner', { title: 'Petowner Page'});
});

module.exports = router;
