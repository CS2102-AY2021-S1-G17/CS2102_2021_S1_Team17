var express = require('express');
var router = express.Router();
const db = require("../db/index.js");
/* GET signup page. */ 
router.get('/', function(req, res) { 
    res.render('signup', { title: 'Signup Page', 
    message:req.flash('signupMessage') }); 
}); 

/* GET Profile page. */ 
router.get('/profile',  function(req, res, next) {
    res.render('profile', { title: 'Profile Page', user : req.user,
    avatar: gravatar.url(req.user.email ,  {s: '100', r: 'x', d:
    'retro'}, true) });
}); 

router.post("/", async function (req, res) {
    if (req.body.role === 'pet_owner') {
        try {
            await db.query("INSERT INTO Users (phone_no, password) VALUES ($1, $2);",
                [req.body.phoneno, req.body.password]);
            await db.query("INSERT INTO pet_owner(phone_no, password) VALUES ($1, $2);",
                [req.body.phoneno, req.body.password]);
            req.flash("success", "Sign up success.");
        } catch (e) {
            req.flash("error", "Sign up failed.");
        } finally {
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

});

module.exports = router;