var express = require('express');
var router = express.Router();
var passport = require('passport');
/* GET login page. */ 
router.get('/', function(req, res, next) { 
  if (req.user) {
    return res.redirect("/" + req.user.role);
  } else {
    res.render('login', { title: 'Login Page', message:
    req.flash('loginMessage') }); 
  }
}); 

router.post("/",
  function (req, res, next) {
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
});

router.get("/logout", function (req, res) {
  req.logout();
  res.redirect("/");
});

module.exports = router;
