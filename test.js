require('coffee-script');
require('amd-loader');
async = require('async');
// Setup Mocha
var Mocha = require('mocha');
var mocha = new Mocha({
  ui: 'bdd',
  reporter: 'spec'
});
// Add assertion libraries
var chai = require('chai');
chai.use(require('sinon-chai'));
global.expect = chai.expect;
global.sinon = require('sinon');
// Add postgres connection details
global.pgConfig = {
  dialect: 'postgres',
  host: 'localhost',
  database: 'brmtest',
  user: 'brmtest',
  password: '53cr3t p455w0rd'
};

// Setup the database tables
pg = require('pg');
client = new pg.Client(pgConfig);
client.query('DROP TABLE IF EXISTS test_models');
client.query('CREATE TABLE test_models (id serial NOT NULL, "strField" character varying(255), CONSTRAINT "primary" PRIMARY KEY (id));');
client.query("INSERT INTO test_models(\"strField\") VALUES ('TEST');");
client.query("INSERT INTO test_models(\"strField\") VALUES ('TEST2');");


// Find all test files, and run the tests
var glob = require('glob');
glob('test/**/*.coffee', function(err, files) {
  if(err){
    throw err;
  }
  var file, i, len;
  for (i = 0, len = files.length; i < len; i++) {
    mocha.addFile(files[i]);
  }
  mocha.run(function(failures){
    if (!failures) {
      process.exit();
    }
    else {
      process.exit(1);
    }
  });

});
