
/*
 * GET home page.
 */

var sbcfg = require('../stackmob.cfg.js');
var StackMob = require("stackmob-client")({
	publicKey: sbcfg.stackmob_api_key,
	secure: true,
	apiVersion: 1
});

exports.index = function(req, res){
  res.render('index', { title: '7 Breaths Data' });
};
