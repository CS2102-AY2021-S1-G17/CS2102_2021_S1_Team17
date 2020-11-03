const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const db = require('../db');
const bcrypt = require('bcrypt');
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
          usernameField: 'phoneno',
          passwordField: 'password'
        },
        function(req, phoneno, password, done) { 
            db.query("SELECT * from USERS u JOIN " + req.body.role + " v ON u.phone = v.phone WHERE u.phone = $1",
            [phoneno], (err, results) => {
                if (err){
                    return done(null, false, { message: "an error occures while trying to access db" })
                }
                console.log(results.rows);

                if (results.rows.length > 0) {
                    const user = results.rows[0];

                    bcrypt.compare(password, user.password, (err, isMatch) => {
                        if (err) {
                            console.log(err);
                        }
                        if (isMatch) {
                            return done(null, user);
                        } else {
                        //password is incorrect
                            return done(null, false, { message: "Password is incorrect" });
                        }
                    });
                } else {
                   return done(null, false, req.flash('loginMessage', 'No user found.')); 
                }
            });
      }))
  };