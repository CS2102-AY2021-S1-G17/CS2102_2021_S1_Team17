var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var app = express();
var flash = require('connect-flash');
require('dotenv').config();
var session = require('express-session');
var indexRouter = require('./routes/index');
var poRouter = require('./routes/pet_owner');
var ctRouter = require('./routes/care_taker');
var adRouter = require('./routes/admin');
var boRouter = require('./routes/both');

//passport
var passport = require("passport");
// const initializePassport = require("./auth/passportConfig");
// initializePassport(passport);

// view engine setup
require('./auth/init').initPassport();
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(logger('dev'));
app.use(flash());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

//app.use(session({ cookie: { maxAge: 60000 }, 
//  secret: 'woot',
//  resave: false, 
//  saveUninitialized: false}));

app.use(
  session({
    secret:"secret",
    resave:false,
    saveUninitialized:false
  })
);

app.use(passport.initialize());
app.use(passport.session());

app.use('/css', express.static(__dirname + '/node_modules/bootstrap/dist/css'));
app.use('/', indexRouter);
app.use('/pet_owner', poRouter);
app.use('/care_taker', ctRouter);
app.use('/admin', adRouter);
app.use('/both', boRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
