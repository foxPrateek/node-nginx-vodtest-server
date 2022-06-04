

require('rootpath')();
const express = require('express');
const app = express();
'use strict';
const fs = require('fs');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('_helpers/jwt');
const errorHandler = require('_helpers/error-handler');

var auth = require('./users/users.controller');
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());

// use JWT auth to secure the api
app.use(jwt());

// api routes
app.use('/users', auth);

app.use(bodyParser.json());

app.use(bodyParser.urlencoded({ extended: true }));


var AWS = require('aws-sdk');
AWS.config.region = 'ap-south-1';

var mediaconvert_ep = null;
var queuearn = null;

async function init() {

const mediaConvert = new AWS.MediaConvert({apiVersion: '2017-08-29'});
 var  params = {
            MaxResults: 0,
        };

        try {
            const data = await mediaConvert.describeEndpoints(params).promise();
            console.log("MediaConvert endpoint is ", data);
            if (data.Endpoints[0].Url.isNull != true ) {
                mediaconvert_ep = data.Endpoints[0].Url ;
                console.log('********MediaConvert Endpoint is ***********\t'+ mediaconvert_ep);
            }
        } catch (err) {
            console.log("MediaConvert Error", err);
            throw err;
        }

var mediaconvert = new AWS.MediaConvert({
  endpoint: mediaconvert_ep
});

 params = {
  Name: 'Default' 
};



mediaconvert.getQueue(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else  {   
    console.log(data);           // successful response 
    queuearn = data.Queue.Arn ;	  
  }	
});

}

init();
console.log(" Out of init");

// on the request to root (localhost:3000/)
app.post('/transcode',auth, function (req, res) {

var lambda = new AWS.Lambda();


var data = req.body ; 
console.log("Got Body...\n",  req.body);
	
//fs.readFile(eventfile, (err, data) => {

//if (err) throw err;
let stData = JSON.stringify(data);
	

//console.log("data is -----",stData);

var params = {
    FunctionName: 'mediacloud-vod-transcode-lambda', // the lambda function we are going to invoke
    InvocationType: 'RequestResponse',
    LogType: 'Tail',
    Payload: stData
  };

  lambda.invoke(params, function(err, rdata) {
    if (err) {
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(rdata, null, 2));
    }
  })
});


// Create DynamoDB service object.
var ddb = new AWS.DynamoDB({ apiVersion: "2012-08-10" });


async function getdata(params,callback) {

var result = await  ddb.scan(params).promise()

//console.log("Result is ....",JSON.stringify(result));

return callback(null,result);
};


async function dbtable (houseid ,starttime,endtime,callback,res){

 var params ;
 if ((starttime !=null) && (endtime !=null) && (houseid == null)) {
     params = {
        // Specify which items in the results are returned.
       FilterExpression: "startTimestamp BETWEEN :sttime and :endtime",
       // Define the expression attribute value, which are substitutes for the values you want to compare.
       ExpressionAttributeValues: {
       ":sttime" : {S: starttime},
       ":endtime" : {S: endtime}
     },
    TableName: "mediacloud-vod-asset-details",
   }
 }
 else if (houseid != null) {
       params = {
        // Specify which items in the results are returned.
         FilterExpression: "houseID = :houseid",
       // Define the expression attribute value, which are substitutes for the values you want to compare.
         ExpressionAttributeValues: {
             ":houseid" : {S: houseid}
     },
     // Set the projection expression, which are the attributes that you want.
    TableName: "mediacloud-vod-asset-details",
  }
}
  
 getdata(params,function(err,data){
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(data, null, 2));
  });
}


app.get('/dbtable',auth, function (req, res) {
var query = require('url').parse(req.url,true).query;

var houseid =req.query.houseid ;
var starttime= req.query.starttime;
var endtime = req.query.endtime ;

for (const key in req.query) {
  console.log(key, req.query[key])
}

 dbtable(houseid,starttime,endtime,null,res);
});

app.get('/joblist',auth, function (req, res) {


var maxresults;

if (!req.query.maxresults)
   maxresults = 5 ;
else 
   maxresults = parseInt(req.query.maxresults,10);


console.log("Mediadiaconvert EP is *****", mediaconvert_ep);
console.log("Queue arn is *****",queuearn );
AWS.config.mediaconvert = {endpoint : mediaconvert_ep};
var params = {
  MaxResults: maxresults,
  Order: 'ASCENDING',
  Queue: queuearn,
  Status: req.query.state
};

// Create a promise on a MediaConvert object
var endpointPromise = new AWS.MediaConvert({apiVersion: '2017-08-29'}).listJobs(params).promise();

// Handle promise's fulfilled/rejected status
endpointPromise.then( function(data) {
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(data, null, 2));
        //res.send(data);         
      },
      function(err) {
      console.log("Error", err);
    }
 );
//});
});


// Change the 404 message modifing the middleware
app.use(function(req, res, next) {
    res.status(404).send("Sorry, that route doesn't exist. Have a nice day :)");
});

// global error handler
app.use(errorHandler);
 

// start server
const port = process.env.NODE_ENV === 'production' ? 80 : 3000;
const server = app.listen(port, function () {
    console.log('Server listening on port ' + port);
});
