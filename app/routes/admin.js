var express = require('express');
var router = express.Router();
var db = require('../db');

router.all("*", function (req, res, next) {
    if (!req.user || req.user.role != 'admin') {
        return res.redirect("/");
    } else {
        next();
    }
});

router.get('/', async(req, res, next) => { 
    try {
        var data = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        var bids = await db.query("SELECT * FROM  admin_view_bids();");
        res.render('admin/admin', { title: 'Admin Page', bids: bids.rows, profile: data.rows[0]});
    } catch (err) {
        throw err;
    }
});
router.get('/salary', async(req, res, next) => { 
    try {
        var data = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        var salary = await db.query("SELECT * FROM  admin_view_unpaid_salary();");
        res.render('admin/admin_salary', { title: 'Admin Page', salary: salary.rows, profile: data.rows[0]});
    } catch (err) {
        throw err;
    }
});
/* Initialise salary for the current year. */ 
router.post('/init', async(req, res)=> {
    try{
      var year = new Date().getFullYear();
      await db.query("CALL init_avail_salary_year($1);",[year]);
    } catch (err) {
      throw err;
    } finally {
      res.redirect("/admin");
    }
  });

module.exports = router;
