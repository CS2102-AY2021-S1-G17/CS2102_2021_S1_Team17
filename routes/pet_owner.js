var express = require('express');
const { syncBuiltinESMExports } = require('module');
var db = require('../db');
//const { route } = require('.');
//const { syncBuiltinESMExports } = require('module');
var router = express.Router();

router.all("*", function (req, res, next) {
  if (!req.user || req.user.role != 'Pet Owner') {
      return res.redirect("/");
  } else {
      next();
  }
});

router.get('/', async(req, res)=> { 
    try{
      var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT * FROM po_view_accepted_bids($1)",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM po_view_upcoming_bids($1)",[req.user.phone]);
      var accepted_bids = data2.rows;
      var pending_bids = data3.rows;
      console.log(accepted_bids);
      console.log(pending_bids);
      //console.log(future_work); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('pet_owner/po_profile', { title: 'Petowner Page', profile:data.rows[0], accepted_bids:accepted_bids, pending_bids:pending_bids, successFlash: req.flash("success"),
      errorFlash: req.flash("error")});
    } catch (err) {
      throw err;
    }
});

router.get('/po_profile',  async(req, res, next)=> {
  try{
      var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
      var data2 = await db.query("SELECT * FROM po_view_accepted_bids($1)",[req.user.phone]);
      var data3 = await db.query("SELECT * FROM po_view_upcoming_bids($1)",[req.user.phone]);
      var accepted_bids = data2.rows;
      var pending_bids = data3.rows;z
      //console.log(future_work); //contains [petowner, po_phone, pet_name, start_date ,end_date, total_cost, transfer_method, payment_method]
      res.render('pet_owner/po_profile', { title: 'Petowner Page', profile:data.rows[0], accepted_bids:accepted_bids, pending_bids:pending_bids, successFlash: req.flash("success"),
      errorFlash: req.flash("error")});
    } catch (err) {
      throw err;
    }
});

router.post('/profile', async(req, res)=> {
  try{
    let {local} = req.body;
    await db.query("UPDATE pet_owner SET transfer_location = $1 WHERE phone=$2;",
    [local, req.user.phone])
    console.log(req.body);
    req.flash("success", "Update successfully.");
  } catch (err) {
    req.flash("error", "Unable to Update.");
    throw err;
  } finally {
    res.redirect("/pet_owner");
  }
});

router.post('/pay', async(req, res)=> {
  try{
    let {po_phone, ct_phone, pet_name, start_date, end_date, pay} = req.body;
    
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

    await db.query("CALL change_bid_status($1, $2, $3,$4, $5,'Success')",[parseInt(po_phone), parseInt(ct_phone), pet_name, start, end]);

    console.log(req.body);
    req.flash("success", "Update successfully.");
  } catch (err) {
    req.flash("error", "Unable to Update.");
    throw err;
  } finally {
    res.redirect("/pet_owner");
  }
});

router.get('/pets',  async(req, res, next) => {
    try{
        var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
        var data2 = await db.query("SELECT * FROM po_view_pets($1);",[req.user.phone]);
        var pet_list = data2.rows;
        res.render('pet_owner/po_pets_profile', { title: 'PetOwner Page', profile:data.rows[0], pet_list:pet_list, successFlash: req.flash("success"),
        errorFlash: req.flash("error")});
        //db.query("CALL add_pet($1, $2, $3, $4);", req.user.phone, req.owns_pet.name, req.owns_pet.special_requirements, req.owns_pet.category_name)

    } catch (err) {
        throw err;
    }
}); 

router.post('/pets', async function(req, res) {
  try {
    await db.query("CALL add_pet($1, $2, $3, $4);", [req.user.phone, req.body.petname,  req.body.petrequire, req.body.category]);
    req.flash("success", "Update successfully.");
  }  catch (err) {
    console.log(req.body);
    console.log(err);
    req.flash("error", "Unable to Update.");
    throw err;
  } finally {
    res.redirect("/pet_owner/pets");
  }
});

router.post('/delete', async function(req, res) {
  try {
    await db.query("DELETE FROM owns_pet WHERE phone=$1 AND name=$2", [req.user.phone, req.body.pet]);
    req.flash("success", "Delate successfully.");
  }  catch (err) {
    console.log(req.body);
    req.flash("error", "Unable to Delete.");
    throw err;
  } finally {
    res.redirect("/pet_owner/pets");
  }
});

router.get('/history', async(req, res, next)=> {
  var data = await db.query("SELECT * FROM po_view_upcoming_bids($1);",[req.user.phone]);
  var data2 = await db.query("SELECT * FROM po_view_accepted_bids($1);",[req.user.phone]);  
  var data3 = await db.query("SELECT * FROM po_view_past_trans($1);",[req.user.phone]);
  console.log(data3.rows);
  res.render('pet_owner/po_history', { title: 'History Page', po_history: data3.rows, pending_bids: data.rows, accepted_bids: data2.rows, past_trans: data3.rows,
  successFlash: req.flash("success"),
  errorFlash: req.flash("error")});
});

router.post('/feedback', async(req, res)=> {
  try{
    console.log(req.body);
  } catch (err) {
    throw err;
  } finally {
    res.redirect("/pet_owner");
  }
});

router.get('/bid',  async(req, res, next)=> {
  var data = await db.query("SELECT * FROM pet_owner po WHERE po.phone=$1;",[req.user.phone]);
  var data2 = await db.query("SELECT * FROM care_taker;");
  res.render('pet_owner/po_bid', { title: 'Bid Page', user : req.user, profile:data.rows[0], search_ct:data2.rows , successFlash: req.flash("success"),
errorFlash: req.flash("error")});
}); 

router.post('/create_bid', async(req, res)=> {
  try{
    await db.query("CALL place_bid($1,$2,$3,$4,$5,$6,$7);",[req.user, req.body.ctphone, req.body.petname, req.body.start, req.body.end, req.body.transfer, req.body.payment]);
    req.flash("success", "Bid successfully.");
  } catch (err) {
    console.log(err);
    console.log(req.body);
    req.flash("error", "Bid Should Be placed 3 days in advance.");
    throw err;
  } finally {
    res.redirect("/pet_owner/bid");
  }
});

router.get('/search',  function(req, res, next) {
      res.render('pet_owner/po_bid', { title: 'Bid Page', user : req.user, successFlash: req.flash("success"),
  errorFlash: req.flash("error")});
}); 
module.exports = router;
