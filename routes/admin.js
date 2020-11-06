var express = require('express');
var router = express.Router();
var db = require('../db');

router.all("*", function (req, res, next) {
    if (!req.user || req.user.role != 'Admin') {
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
router.get('/underperforming', async(req, res, next) => { 
    try {
        var year = new Date().getFullYear();
        console.log(year);
        var data = await db.query("SELECT * FROM  underperforming_fulltime($1);", [year]);
        var profile = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        console.log(data.years)
        res.render('admin/underperforming', { title: 'Admin Page', user:data.rows, profile: profile.rows[0]});
    } catch (err) {
        throw err;
    }
});

router.get('/user', async(req, res, next) => { 
    try {
        var data = await db.query("SELECT * FROM  users;");
        var profile = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        res.render('admin/manage_user', { title: 'Admin Page', users:data.rows, profile: profile.rows[0]});
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

  /* Delete User */
  router.post('/delete', async(req, res)=> {
    try{
      console.log(req.body);
    } catch (err) {
      throw err;
    } finally {
      res.redirect("/admin/user");
    }
  });

module.exports = router;
