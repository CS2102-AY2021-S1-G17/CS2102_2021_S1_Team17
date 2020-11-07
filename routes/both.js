var express = require('express');
var db = require('../db');
var router = express.Router();

router.all("*", function (req, res, next) {
  console.log(req.user)
  if (!req.user || req.user.role != 'Both') {
      return res.redirect("/");
  } else {
      next();
  }
});

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT category_name FROM capable WHERE phone=$1;",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM ct_view_pending_bids($1)",[req.user.phone]);
      var data4 = await db.query("SELECT * FROM ct_view_future_work($1)",[req.user.phone]);
      var cat_list = [];
      var pending_bids = data3.rows; 
      var future_work = data4.rows;　
      for (let i = 0; i < data2.rows.length; i++) {
        Object.keys(data2.rows[i]).forEach(function(key) {
          cat_list.push(data2.rows[i][key])
        });
      }
      //console.log(data.rows[0]); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('both/profile', { title: 'CT & PO\'s Page', profile:data.rows[0], cat_list: cat_list, pending_bids:pending_bids, future_work: future_work, successFlash: req.flash("success"),
      errorFlash: req.flash("error")});
    } catch (err) {
      throw err;
    }
});

/* Update caretaker category. */ 
router.post('/category', async(req, res)=> {
  try{
    cat=req.body.cat;
    dog=req.body.dog;
    bird=req.body.bird;
    cat_price=req.body.cat_price;
    dog_price=req.body.dog_price;
    bird_price=req.body.bird_price;
    if (req.body.is_full_time == 'true') {
      if (cat) {
        await db.query("CALL add_capable($1, 'cat', 1);",[req.user.phone]);
      } 
      if (dog) {
        await db.query("CALL add_capable($1, 'dog', 1);",[req.user.phone]);
      } 
      if (bird) {
        await db.query("CALL add_capable($1, 'bird', 1);",[req.user.phone]);
      } 
    } else {
      if (cat) {
        await db.query("CALL add_capable($1, 'cat', $2);",[req.user.phone, cat_price]);
      }
      if (dog) {
        await db.query("CALL add_capable($1, 'dog', $2);",[req.user.phone, dog_price]);
      }
      if (bird) {
        await db.query("CALL add_capable($1, 'bird', $2);",[req.user.phone, bird_price]);
      }
      req.flash("success", "Update successfully.");
    }
  } catch (err) {
    req.flash("error", "Unable to Update.");
  } finally {
    res.redirect("/both");
  }
});

/* Update bid status. */ 
router.post('/update_status', async(req, res)=> {
  try{
    let {po_phone, ct_phone, pet_name, start_date, end_date, accept,decline} = req.body;
    
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
    var start = convert(start_date);
    var end = convert(end_date);

    if (accept) {
      await db.query("CALL change_bid_status($1, $2, $3,$4, $5,'Accepted')",[parseInt(po_phone), parseInt(ct_phone), pet_name, start, end])
    } else {
      await db.query("CALL change_bid_status($1, $2, $3,$4, $5,'Rejected')",[parseInt(po_phone), parseInt(ct_phone), pet_name, start, end])
    }
    req.flash("success", "Update successfully.");
  } catch (err) {
    req.flash("error", "Unable to Update.");
  } finally {
    res.redirect("/both");
  }
});

/* Update profile */ 
router.post('/profile', async(req, res)=> {
  try{
    let {transfer_location, name, bank_account} = req.body;
    if (transfer_location) {
      await db.query("UPDATE care_taker SET transfer_location = $1 WHERE phone=$2;",
      [transfer_location, req.user.phone])
    }
    if (name) {
      await db.query("UPDATE care_taker SET name = $1 WHERE phone=$2;",
      [name, req.user.phone])
    }
    if (bank_account) {
      await db.query("UPDATE care_taker SET bank_account = $1 WHERE phone=$2;",
      [bank_account, req.user.phone])
    }
    req.flash("success", "Update successfully.");
  } catch (err) {
    req.flash("error", "Unable to Update.");
  } finally {
    res.redirect("/both");
  }
});

/* Update availablity. */ 
router.post('/availability', async(req, res)=> {
  try{
    let {start, end} = req.body;
    var data = await db.query("SELECT is_full_time FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var fulltime = data.rows.is_full_time;
    if (fulltime) {
      await db.query("CALL take_leave($1, $2, $3)",[req.user.phone, start, end]);
    } else {
      await db.query("CALL claim_avail($1, $2, $3)",[req.user.phone, start, end]);
    }
    req.flash("success", "Update successfully.");
  } catch (err) {
    req.flash("error", "Unable to Update.");
  } finally {
    res.redirect("/both");
  }
});

router.get('/salary',  async(req, res, next)=> {
  try {
    var data = await db.query("SELECT * FROM care_taker ct WHERE ct.phone=$1;",[req.user.phone]);
    var time = await db.query('SELECT pay_time FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    var salary = await db.query('SELECT amount FROM salary WHERE phone=$1 ORDER BY pay_time;', [req.user.phone]);
    var time_list = [];
    var salary_list = [];
    var date = new Date();
    for (let i = 0; i < time.rows.length; i++) {
        time_list.push(time.rows[i].pay_time);
    }
    for (let i = 0; i < salary.rows.length; i++) {
      salary_list.push(salary.rows[i].amount);
    } 
    var time_l = time_list.length;
    var salary_l = salary_list.length;
    if (time_list.length < 12) {
      for (let i = 0; i < 12-time_l; i++) {
        time_list.push(new Date(date));
        date.setMonth(date.getMonth() + 1);
      }
    }
    if (salary_list.length < 12) {
      for (let i = 0; i < 12-salary_l; i++) {
        salary_list.push(0);
      }
    }
    res.render('both/ct_salary', { title: 'Salary', salary:salary_list, time:time_list, profile:data.rows[0], successFlash: req.flash("success"),
    errorFlash: req.flash("error")});
  } catch(err) {
    throw err;
  }
}); 

router.get('/history', async(req, res, next)=> {
  var data3 = await db.query("SELECT * FROM ct_view_past_trans($1);",[req.user.phone]);
  res.render('both/ct_history', { title: 'History Page', history: data3.rows, successFlash: req.flash("success"),
  errorFlash: req.flash("error")});
}); 

module.exports = router;