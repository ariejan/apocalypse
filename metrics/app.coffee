# Metric Server
#
# This metric server will accept incoming push updates from configured hosts. It will translate
# the incoming metrics and publish them on the `metrics` channel for further processing.
#
# The metrics server has no public views (e.g. for browsers).

# Configuration
global.config = require('../config')

# Require external libs, including
# Express for HTTP and
# socket.io for Websockets
sys      = require('sys')
express  = require('express')
app      = express.createServer()


############################################
#### Redis
############################################
redis           = require("redis")
client          = redis.createClient()

# Handle redis errors gracefully
client.on "ready", () ->
  console.log "Metrics server connected to redis"

client.on "error", (err) ->
  console.log "Metrics server could not connect to redis: " + err

############################################
#### HTTP Authentication
############################################
authorize_for_host = (req, res, next) ->
  if req.headers.authorization and req.headers.authorization.search('Basic ') == 0
    buffer  = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString()
    auth    = "#{config.metrics.username}:#{config.metrics.password}"
    if buffer == auth
      next()
    else
      res.header 'WWW-Authenticate', 'Basic realm="Apocalypse Metrics Server"'
      res.send('Authentication required', 401)
  return

############################################
#### Express / API
############################################

# Some Express setup
app.configure () ->
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.errorHandler(
    dumpExceptions: true,
    showStack: true
  )

# GET /
# Just to show people to go away.
app.get '/', (req, res) ->
  res.render('index')

# POST /api/metrics
# Store recorded metrics data
app.post '/api/metrics/:hostid', authorize_for_host, (req, res) ->
  metric_data =
    hostid:     req.params.hostid
    type:       'metrics'
    load:       req.body
    created_at: new Date()
  
  # Post raw metrics to redis for further processing
  client.publish "metrics", JSON.stringify(metric_data)
  
  updated_at_message =
    hostid: req.params.hostid
    message_id: "updated_at"
    status: "ok"
    metric_type: "updated_at"
    type: 'status'
    last_value: new Date()
  
  client.publish "status", JSON.stringify(updated_at_message)

  # Say thank-you to the client
  res.send { status: 'OK' }

# Start the server / web API
app.listen config.metrics.port, () ->
  console.log("-> Apocalypse Metrics Server ready on http://#{config.metrics.hostname}:#{config.metrics.port}")
