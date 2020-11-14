var express = require('express');
var router = express.Router();
var db = require('../db');
const bcrypt = require("bcrypt");

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
        var bids = await db.query("SELECT * FROM  admin_view_accepted_bids();");
        res.render('admin/admin', { title: 'Admin Page', bids: bids.rows, profile: data.rows[0], successFlash: req.flash("success"),
        errorFlash: req.flash("error")});
    } catch (err) {
        throw err;
    }
});
router.get('/salary', async(req, res, next) => { 
    try {
        var data = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        var salary = await db.query("SELECT * FROM  admin_view_unpaid_salary();");
        res.render('admin/admin_salary', { title: 'Admin Page', salary: salary.rows, profile: data.rows[0], successFlash: req.flash("success"),
        errorFlash: req.flash("error")});
    } catch (err) {
        throw err;
    }
});
router.get('/underperforming', async(req, res, next) => { 
    try {
        var year = new Date().getFullYear();
        var data = await db.query("SELECT * FROM  underperforming_fulltime($1);", [year]);
        var profile = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        res.render('admin/underperforming', { title: 'Admin Page', user:data.rows, profile: profile.rows[0], successFlash: req.flash("success"),
        errorFlash: req.flash("error")});
    } catch (err) {
        throw err;
    }
});

router.get('/user', async(req, res, next) => { 
    try {
        var data = await db.query("SELECT * FROM  users;");
        var profile = await db.query("SELECT * FROM admin ad WHERE ad.phone=$1;",[req.user.phone]);
        res.render('admin/manage_user', { title: 'Admin Page', users:data.rows, profile: profile.rows[0],successFlash: req.flash("success"),
        errorFlash: req.flash("error")});
    } catch (err) {
        throw err;
    }
});
/* Initialise salary for the current year. */ 
router.post('/init', async(req, res)=> {
    try{
      var year = new Date().getFullYear();
      await db.query("CALL init_avail_salary_year($1);",[year]);
      req.flash("success", "Initialsed successfully.");
    } catch (err) {
      req.flash("error", "Unable to initailise.");
      throw err;
    } finally {
      res.redirect("/admin");
    }
  });

  /* Delete User */
  router.post('/delete', async(req, res)=> {
    try{
      //DELETE FROM table_name WHERE condition;
      await db.query("DELETE FROM users WHERE phone=$1;",[req.body.phone]);
      req.flash("success", "Delete user successfully.");
    } catch (err) {
      req.flash("error", "Unable to Delete.");
      throw err;
    } finally {
      res.redirect("/admin/user");
    }
  });

   /* Add Admin */
   router.post('/add', async(req, res)=> {
    try{
      let hashedP = await bcrypt.hash(req.body.password, 10);
      await db.query("CALL register_admin($1, $2, $3);",
            [req.body.phone_no, hashedP, req.body.name]);
        req.flash("success", "Add admin successfully.");
    } catch (err) {
      req.flash("error", "Unable to Add.");
      throw err;
    } finally {
      res.redirect("/admin/user");
    }
  });

    /* Update ct salary */
    router.post('/update_salary', async(req, res)=> {
    try{
      function convert(str) {
        var mnths = {
            Jan: "01",
            Feb: "02",
            Mar: "03",
            Apr: "04",
            May: "05",
            Jun: "06",
            Jul: "07",
            Aug: "08",
            Sep: "09",
            Oct: "10",
            Nov: "11",
            Dec: "12"
          },
          date = str.split(" ");
        return [date[3], mnths[date[1]], date[2]].join("-");
      }
      let {phone, ct_phone, ct_pay_time} = req.body;
      await db.query("INSERT INTO pay VALUES ($1, $2, $3)",[parseInt(phone), parseInt(ct_phone), convert(ct_pay_time)]);
      console.log(req.body);
    } catch (err) {
      req.flash("error", "Unable to Update.");
      throw err;
    } finally {
      res.redirect("/admin/salary");
    }
  });

   /* Update Status */
   router.post('/status', async(req, res)=> {
    console.log(req.body);
    function convert(str) {
      var mnths = {
          Jan: "01",
          Feb: "02",
          Mar: "03",
          Apr: "04",
          May: "05",
          Jun: "06",
          Jul: "07",
          Aug: "08",
          Sep: "09",
          Oct: "10",
          Nov: "11",
          Dec: "12"
        },
        date = str.split(" ");
      return [date[3], mnths[date[1]], date[2]].join("-");
    }
    var start = convert(req.body.start_date);
    var end = convert(req.body.end_date);
    var po_p = parseInt(req.body.po_phone);
    var ct_p = parseInt(req.body.ct_phone);

    try{
      await db.query("CALL change_bid_status($1, $2, $3,$4, $5,'Success')",[po_p, ct_p, req.body.pet_name, start, end]);
      req.flash("success", "Update successfully.");
    } catch (err) {
      console.log(err);
      req.flash("error", err);
      throw err;
    } finally {
      res.redirect("/admin");
    }
  });

module.exports = router;
