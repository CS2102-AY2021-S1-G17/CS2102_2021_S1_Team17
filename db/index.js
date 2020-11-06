const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

function asyncQuery(text, params) {
  return pool
    .query(text, params)
    .then(data => {
      return data;
    })
    .catch(err => {
      throw err;
    });
}

// Uses the callback given to process the output
function syncQuery(text, params, callback) {
  const start = Date.now();
  return pool.query(text, params, (err, res) => {
    callback(err, res);
  });
}

function query(...args) {
  if (args.length === 1 || (args.length === 2 && typeof args[0] === 'string' && typeof args[1] !== 'function')) {
    // query (and params), no callback -> async
    return asyncQuery(args[0], args[1] ? args[1] : []);
  }
  if (typeof args[1] === 'function') {
    // query and callback, empty params
    return syncQuery(args[0], [], args[1]);
  }
  return syncQuery(...args);
}

module.exports = { query };
