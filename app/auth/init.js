const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const db = require('../db');
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
            db.query("select * from users u join " + req.body.role + " v on u.phone = v.phone where u.phone = $1",
            [phoneno], (err, data) => {
               if (err)
                   return done(err);
                if (!data.rows.length) {
                   return done(null, false, req.flash('loginMessage', 'No user found.')); 
               } 
               
               if (!(data.rows[0].password == password))
                   return done(null, false, req.flash('loginMessage', 'Oops! Wrong password.'));
               var user = data.rows[0];
               user.role = req.body.role;
               return done(null, user);		
            });
      }))
  };