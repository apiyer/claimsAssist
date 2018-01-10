var express = require('express');
var app = express();
var port = process.env.PORT || 8080;
var bodyParser = require('body-parser');
var bcrypt = require('bcrypt-nodejs');

var morgan = require('morgan');
var config = require('./config');
var longjohn = require('longjohn');
var dynamoose = require('dynamoose');

dynamoose.AWS.config.update({
    accessKeyId: config.accessKeyId,
    secretAccessKey: config.secretAccessKey,
    region: config.region || 'us-east-1'
});

var path = require('path');
var cors = require('cors');
var corsOptions = {
    origin: '*',
    methods: 'DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT',
    allowedHeaders: 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
}

app.use(cors(corsOptions));
var router = express.Router();
app.options('*', cors());
var appRoutes = require('./app/routes/api')(router);
app.use(morgan('dev'));
require('longjohn');
app.use(bodyParser.urlencoded({
    extended: false
}));
app.use(bodyParser.json());
app.use(express.static(__dirname + '/public'));
app.use('/api', appRoutes);


app.get("/healthcheck", (req, res) => {
    res.send('InsuranceCo API Lambda is Responding!');
});

module.exports = app;
