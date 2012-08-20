require('coffee-script');
require('amd-loader');
var async = require('async');
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

function setupDB(cb){
  console.log("Setting up database...");
  // Setup the database tables
  var pg = require('pg');
  var client = new pg.Client(pgConfig);
  async.series([
    function(cb2){
      client.connect(cb2)
    },
    // -----------------------------------------------------------------------
    // TestModel SETUP
    function(cb2){
      var query = client.query('DROP TABLE IF EXISTS test_models');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('CREATE TABLE test_models (' +
          '"id" serial NOT NULL,' +
          '"strField" character varying(255),' +
          '"createdAt" timestamp without time zone NOT NULL,' +
          '"updatedAt" timestamp without time zone NOT NULL);');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query("INSERT INTO test_models(\"strField\", \"createdAt\", \"updatedAt\")" +
          "VALUES ('TEST', '2011-01-01 12:12:12', '2011-01-01 12:12:12');");
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query("INSERT INTO test_models(\"strField\", \"createdAt\", \"updatedAt\")" +
          "VALUES ('TEST2', '2011-01-01 12:12:12', '2011-01-01 12:12:12');");
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query("INSERT INTO test_models(\"strField\", \"createdAt\", \"updatedAt\")" +
          "VALUES ('TEST3', '2011-01-01 12:12:12', '2011-01-01 12:12:12');");
      query.on('end', function(){
        cb2(null);
      });
    },
    // -----------------------------------------------------------------------
    // TestModel2 SETUP
    function(cb2){
      var query = client.query('DROP TABLE IF EXISTS test_model2s');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('CREATE TABLE test_model2s (' +
          '"id" serial PRIMARY KEY, ' +
          '"strField" character varying(255), ' +
          '"intField" integer, ' +
          '"createdAt" timestamp without time zone NOT NULL,' +
          '"updatedAt" timestamp without time zone NOT NULL);');
      query.on('end', function(){
        cb2(null);
      });
    },
    // -----------------------------------------------------------------------
    // TestModel3 SETUP
    function(cb2){
      var query = client.query('DROP TABLE IF EXISTS test_model3s');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('CREATE TABLE test_model3s (' +
          '"id" serial PRIMARY KEY, ' +
          '"strField" character varying(255), ' +
          '"intField" integer, ' +
          '"strFieldExclude" character varying(255), ' +
          '"createdAt" timestamp without time zone NOT NULL,' +
          '"updatedAt" timestamp without time zone NOT NULL);');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query("INSERT INTO test_model3s(\"strField\", \"intField\", \"strFieldExclude\", \"createdAt\", \"updatedAt\")" +
          "VALUES ('TEST3', 3, 'INVISIBLE VALUE', '2011-01-01 12:12:12', '2011-01-01 12:12:12');");
      query.on('end', function(){
        cb2(null);
      });
    },
    // -----------------------------------------------------------------------
    // Player and Team SETUP
    function(cb2){
      var query = client.query('DROP TABLE IF EXISTS players');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('DROP TABLE IF EXISTS teams');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('CREATE TABLE teams (' +
          '"id" serial PRIMARY KEY, ' +
          '"name" character varying(255), ' +
          '"founded" timestamp without time zone,' +
          '"createdAt" timestamp without time zone NOT NULL,' +
          '"updatedAt" timestamp without time zone NOT NULL);');
      query.on('end', function(){
        cb2(null);
      });
    },
    function(cb2){
      var query = client.query('CREATE TABLE players (' +
          '"id" serial PRIMARY KEY, ' +
          '"name" character varying(255), ' +
          '"age" integer, ' +
          '"teamId" integer references teams(id), ' +
          '"createdAt" timestamp without time zone NOT NULL,' +
          '"updatedAt" timestamp without time zone NOT NULL);');
      query.on('end', function(){
        cb2(null);
      });
    },
  ],
  function(err, results){
    console.log("Setting up database... DONE");
    cb(err, results);
  });
}

function runTests(cb){
  console.log("Running tests...");
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
        console.log("Running tests... DONE");
        cb(null);
      }
      else {
        console.log("Running tests... FAILED");
        cb(failures);
      }
    });

  });
}
async.series({
    setupDB: setupDB,
    runTests: runTests
  },
  function(err, results){
    if (err){
      console.log(err);
      process.exit(1);
    }
    else {
      process.exit();
    }
  }
);

