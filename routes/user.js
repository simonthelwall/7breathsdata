var sbcfg = require('../stackmob.cfg.js');
var StackMob = require("stackmob-client")({
	publicKey: sbcfg.stackmob_api_key,
	secure: true,
	apiVersion: 1
});

/*
 * GET users listing.
 */

exports.list = function(req, res){
  res.send("respond with a resource");
};

exports.count = function(req, res) {
  var User = StackMob.Model.extend({ schemaName: 'user'});
  var Users = StackMob.Collection.extend({ model: User });
  var users = new Users();
  users.fetch({
  	success: function(results) {
      console.log("user:count | Number of users: " + results.length);
      res.send({count: results.length});
  	},
  	error: function() {
      console.log("user:count | Stackmob fetch error");  		
      res.send({count: 'Not found, please retry'});
  	}
  });
}