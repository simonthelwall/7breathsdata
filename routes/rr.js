/*
 * Respiratory rate model API
 */

var sbcfg = require('../stackmob.cfg.js');
var StackMob = require("stackmob-client")({
	publicKey: sbcfg.stackmob_api_key,
	secure: true,
	apiVersion: 1
});

/*
 * GET users listing.
 */
exports.count = function(req, res) {
  var Model = StackMob.Model.extend({ schemaName: 'rr'});
  var Collection = StackMob.Collection.extend({ model: Model });
  var rr = new Collection();
  rr.fetch({
  	success: function(results) {
      // devices = _.uniq( results.pluck("device") );
      // console.log("Device array after to uniq: " + devices.length);
 
      res.send({count: results.length});
  	},
  	error: function() {
      console.log("rr:count | Stackmob fetch error");  		
      res.send({count: 'Not found, please retry'});
  	}
  });
}