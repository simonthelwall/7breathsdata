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
      var dataPointCount = results.length;
      console.log("rr:count = " + dataPointCount);

      // devices = _.uniq( results.pluck("device") );
      // console.log("Device array after to uniq: " + devices.length);

      /*
       Analyse the number of data points people submit
       */
      var datapointcount = [];
      var grouped = results.groupBy( function(model){ return model.get('device')});
      //console.log("grouped = " + JSON.stringify(grouped,null,2));

      for(device in grouped) { 
          var models = grouped[device];
          console.log('Device: '+device+ " models lenght: " + models.length);
          datapointcount[models.length] = (datapointcount[models.length]) ? datapointcount[models.length]+1 : 1;
      }

      // Fill in the sparse array with zeros
      for(i=1,l=datapointcount.length;i<l;i++){
        if(!datapointcount[i]) {
          datapointcount[i] = 0; 
        }
      }
      res.send({count: dataPointCount, datapointcount: datapointcount});
  	},
  	error: function() {
      console.log("rr:count | Stackmob fetch error");
      res.send({count: 'Not found, please retry'});
  	}
  });
}