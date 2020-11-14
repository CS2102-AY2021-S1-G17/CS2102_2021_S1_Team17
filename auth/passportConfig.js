const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const db = require('../db');
const bcrypt = require("bcrypt");

function initialize(passport) {

    const authenticateUser = (phone, password, done)=>{
        db.query("select * from users u join where u.phone = $1",[phone], (err, results)=>{
            if(err){
                throw err;
            }


            if (results.rows.length > 0) {
                const user = results.rows[0];

                //compare password
                bcrypt.compare(password, user.password, (err, isMatch) => {
                    if (err) {
                        throw err;
                    }
                    if (isMatch){
                        return done(null, user);
                    } else {
                        return done(null, false, req.flash('loginMessage', 'Oops! Wrong password.'));
                    }
                })
            } else {
                return done(null, false, req.flash('loginMessage', 'User not found.'))
            }
        })
    }

    passport.use(
      new LocalStrategy({
          usernameFiled:"phone",
          passwordField:"password"
        }, 
        authenticateUser
      )  
    );

    passport.serializeUser((user, done)=>done(null, user.phone));

    passport.deserializeUser((phone, done)=> {
        db.query("select * from users u join where u.phone = $1", [phone], (err, results)=>{
            if (err) {
                throw err;
            }
            return done(null, results.rows[0]);
        });
    });
}

module.exports = initialize;