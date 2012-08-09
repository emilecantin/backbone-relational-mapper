require('coffee-script');
require('amd-loader');
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
    }
    process.exit();
  });

});
