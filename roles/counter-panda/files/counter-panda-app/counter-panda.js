var http = require('http');
var config = require('./config.json');
var HttpDispatcher = require('httpdispatcher');
var dispatcher = new HttpDispatcher();

var counter = 0

function handleRequest(request, response){
    try {
        console.log("Requested URL: " + request.url);
        dispatcher.dispatch(request, response);
    } catch(err) {
        console.log(err);
    }
}

dispatcher.onGet("/", function(req, res) {
    console.log("GET received");
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('number of posts receieved: ' + counter + '\n');
});

dispatcher.onPost("/", function(req, res) {
    console.log("POST received");
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('POST received\n');
    counter++
});

dispatcher.onError(function(req, res) {
        res.writeHead(404);
        res.end("404 - Page Does not exists");
});

http.createServer(handleRequest).listen(config.port, function(){
    console.log("Server listening on: http://localhost:%s", config.port);
});
