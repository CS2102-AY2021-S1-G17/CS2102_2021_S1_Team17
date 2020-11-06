const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const db = require('../db');
const bcrypt = require("bcrypt");

passport.serializeUser((user, done) => {
    done(null, user);
});
  
passport.deserializeUser((user, done) => {
    done(null, user);
});

exports.initPassport = () => {
    passport.use(
      new LocalStrategy(
        {
          passReqToCallback: true,
          usernameField: 'phone',
          passwordField: 'password'
        },
        function(req, phone, password, done) { 
            db.query("select * from users u where u.phone = $1",[phone], (err, results)=>{
                if(err){
                    throw err;
                }
                if (results.rows.length > 0) {
                    var user = results.rows[0];
    
                    //compare password
                    if(user.role == 'Admin') {
                        if (password == user.password) {
                            user = {...user, role: req.body.role};
                            return done(null, user);
                        } else {
                            return done(null, false, req.flash('error', 'Oops! Wrong password.'));
                        }
                    } else {
                        bcrypt.compare(password, user.password, (err, isMatch) => {
                            if (err) {
                                throw err;
                            }
                            if (isMatch){
                                user = {...user, role: req.body.role};
                                return done(null, user);
                            } else {
                                return done(null, false, req.flash('error', 'Oops! Wrong password.'));
                            }
                        })
                    }
                } else {
                    return done(null, false, req.flash('error', 'User not found.'))
                }
            });
      }))
  };