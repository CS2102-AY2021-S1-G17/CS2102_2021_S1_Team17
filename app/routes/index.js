var express = require('express');
var router = express.Router();
var passport = require('passport');
var db = require('../db');
const bcrypt = require("bcrypt");

/* GET login page. */ 
router.get('/', function(req, res, next) { 
  if (req.user) {
    if (req.user.role == "Pet Owner") {
      return res.redirect("/pet_owner");
    } else if (req.user.role == "Caretake"){
      return res.redirect("/care_taker");
    } else {
      res.render('login', { title: 'Login Page', 
      successFlash: req.flash("success"),
      errorFlash: req.flash("error")}); 
    }
  } else {
    res.render('login', { title: 'Login Page', 
    successFlash: req.flash("success"),
    errorFlash: req.flash("error")}); 
  }
}); 

router.get('/signup', function(req, res, next) { 
  if (req.user) {
    return res.redirect("/" + req.user.role);
  } else {
    res.render('signup', { title: 'Sign up Page', 
    successFlash: req.flash("success"),
    errorFlash: req.flash("error")}); 
  }
}); 
router.post("/signup", async function (req, res, next) {
  /*--------------------------Sign up PO------------------------------ */
  if (req.body.signup_po) {
    let {username, phoneno, password, location, card, petname, category, requirement} = req.body;
    let hashedP = await bcrypt.hash(password, 10);
    try {
        await db.query("CALL register_pet_owner($1, $2, $3, $4, $5, $6, $7, $8);",
            [phoneno, hashedP, location, username, card, petname, requirement, category]);
        req.flash("success", "Sign up success.");
    } catch (e) {
        console.log(e);
        req.flash("error", "Sign up failed.");
    } finally {
        res.redirect("/");
    }      
  } else if (req.body.signup_ct) {   /*-------Sign up CT -----------*/
    let {username, phoneno, password, location, ba, ft, category, price} = req.body;
    let hashedP = await bcrypt.hash(password, 10);
    if (String(price)==="") {
      price = 1;
    };
    try {
      if (ft=="TRUE") {
        await db.query("CALL register_caretaker($1, $2, $3, $4, $5, true, $6, $7);",
            [phoneno, hashedP, String(location), String(username), String(ba), category, price]);
      } else {
        await db.query("CALL register_caretaker($1, $2, $3, $4, $5, false, $6, $7);",
        [phoneno, hashedP, String(location), String(username), String(ba), category, price]);
      }
      req.flash("success", "Sign up success.");
    } catch (e) {
        console.log(e);
        req.flash("error", "Sign up failed.");
    } finally {
        res.redirect("/");
    }      
  } else if (req.body.signup_both) {   /*-------Sign up Both -----------*/
    let {username, phoneno, password, p_location, card, petname, p_category, requirement,
       c_location, ba, b_ft, c_category, b_price} = req.body;
    let hashedP = await bcrypt.hash(password, 10);
    if (String(b_price)==="") {
      b_price = 1;
    };
    try {
        //await db.query("CALL register_caretaker($1, $2, $3, $4, $5, $6, $7, $8);",
        //    [phoneno, hashedP, String(c_location), String(username), String(ba), Boolean(b_ft), c_category, b_price]);
        
        if (b_ft=="TRUE") {
          await db.query("CALL register_caretaker($1, $2, $3, $4, $5, true, $6, $7);",
              [phoneno, hashedP, String(c_location), String(username), String(ba), c_category, b_price]);
        } else {
          await db.query("CALL register_caretaker($1, $2, $3, $4, $5, false, $6, $7);",
          [phoneno, hashedP, String(c_location), String(username), String(ba), c_category, b_price]);
        }
        await db.query("CALL register_pet_owner($1, $2, $3, $4, $5, $6, $7, $8);",
            [phoneno, hashedP, p_location, username, card, petname, requirement, p_category]);
        req.flash("success", "Sign up success.");
    } catch (e) {
        console.log(e);
        req.flash("error", "Sign up failed.");
    } finally {
        res.redirect("/");
    }      
  } 
});
router.post("/", async function (req, res, next) {
        /*--------------------------Login------------------------------ */
      passport.authenticate("local", function (err, user, info) {
        if (err || !user) {
            return res.render("login", {title: 'Login Page', successFlash: req.flash("success"),
            errorFlash: req.flash("error")});
        }
        req.logIn(user, function (err) {
            if (err) {
                return res.render("login", {title: 'Login Page', successFlash: req.flash("success"),
                errorFlash: req.flash("error")});
            }
        });
        if (user.role == "Pet Owner") {
          return res.redirect("/pet_owner");
        } else if (user.role == 'Caretaker') {
          return res.redirect("/care_taker");
        } else if (user.role == 'Both') {
          return res.redirect("/both");
        }else {
          return res.redirect("/admin");
        }
    })(req, res, next);
});

router.get("/logout", function (req, res) {
  req.logout();
  res.redirect("/");
});

module.exports = router;
