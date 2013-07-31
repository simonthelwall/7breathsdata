var sys = require('sys');

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
  	  var _users = results.toJSON();
      console.log("user:count | Number of users: " + _users.length);

      // We can determine the android / ios user split from the device id lenght
      var _count = _users.length, _android = 0, _ios = 0;
      for(var i=0; i<_count; i++) {
      	var result = _users[i];
      	if (result.device.length === 36 ) {
      		_ios++;
      	}
      	else {
      		_android++;
      	}
      }
      res.send({count: _count, ios_count: _ios, android_count: _android});
  	},
  	error: function() {
      console.log("user:count | Stackmob fetch error");  		
      res.send({count: 'Not found, please retry'});
  	}
  });
}