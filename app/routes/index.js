var express = require('express');
var router = express.Router();
var passport = require('passport');
var db = require('../db');
/* GET login page. */ 
router.get('/', function(req, res, next) { 
  if (req.user) {
    return res.redirect("/" + req.user.role);
  } else {
    res.render('login', { title: 'Login Page', message:
    req.flash('loginMessage') }); 
  }
}); 

router.post("/", async function (req, res, next) {
      if (req.body.signup) {
        console.log(req.body)
        if (req.body.role === 'pet_owner') {
          try {
              await db.query("INSERT INTO Users (phone_no, password) VALUES ($1, $2);",
                  [req.body.phoneno, req.body.password]);
              await db.query("INSERT INTO pet_owner(phone_no, password) VALUES ($1, $2);",
                  [req.body.phoneno, req.body.password]);
              req.flash("success", "Sign up success.");
          } catch (e) {
              console.log(e);
              req.flash("error", "Sign up failed.");
          } finally {
            console.log("corr");
              res.redirect("/");
          }
        } else {
            try {
                await db.query("INSERT INTO Users (phone_no, password) VALUES ($1, $2);",
                    [req.body.phoneno, req.body.password]);
                await db.query("INSERT INTO care_taker(phone_no, password) VALUES ($1, $2);",
                    [req.body.phoneno, req.body.password]);
                req.flash("success", "Sign up success.");
            } catch (e) {
                req.flash("error", "Sign up failed.");
            } finally {
                res.redirect("/");
            }
        }
      } else {
        passport.authenticate("local", function (err, user, info) {
            if (err || !user) {
                console.log(err);
                return res.render("login", {title: 'Login Page', message:
                req.flash('loginMessage'), isError: true});
            }
            req.logIn(user, function (err) {
                if (err) {
                    return res.render("login", {title: 'Login Page', message:
                    req.flash('loginMessage'), isError: true});
                }
            });
            return res.redirect("/" + user.role);
        })(req, res, next);
      }
});

router.get("/logout", function (req, res) {
  req.logout();
  res.redirect("/");
});

module.exports = router;
