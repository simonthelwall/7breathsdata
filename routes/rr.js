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
  	  var _rr = results.toJSON();

      var _count = _rr.length;
      for(var i=0; i<_count; i++) {
      	var result = _rr[i];
      }
      res.send({count: _count});
  	},
  	error: function() {
      console.log("rr:count | Stackmob fetch error");  		
      res.send({count: 'Not found, please retry'});
  	}
  });
}