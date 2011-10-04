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
_        = require('underscore')
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
#### Version Check for client information
############################################
client_up_to_date = (body) ->
  client_version = body.client.version.split(/\./);
  latest_version = config.client.latest_version.split(/\./); 
  index          = 0;
  return _.all client_version, (val) ->
    return parseInt(val) >= (parseInt(latest_version[index++]) || 0)

response_body = (body) -> 
  if !client_up_to_date(body)
    return {"code": RESULT_CLIENT_OUTDATED}
  return {"code": RESULT_OK}

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
  host_id = req.params.hostid

  metric_data =
    hostid:     host_id
    type:       'metrics'
    load:       req.body
    created_at: new Date()

  # Post raw metrics to redis for further processing
  client.publish "metrics", JSON.stringify(metric_data)

  updated_at_message =
    hostid: host_id
    message_id: "updated_at"
    status: "ok"
    metric_type: "updated_at"
    type: 'status'
    last_value: new Date()

  # Post a last_updated message to the status channel
  client.publish "status", JSON.stringify(updated_at_message)

  client.sismember 'hostids', host_id, (err, data) ->
    # Add this host *now*
    if data == 0
      console.log "First update from this host; storing host_id: #{host_id}"
      client.sadd "hostids", host_id
      client.publish "status", JSON.stringify(type: 'host', hostid: host_id)

  # Since we heard from the client, we assume it's up. Update
  # the reachability score
  client.zadd "reachability", new Date().getTime(), req.params.hostid

  # Say thank-you to the client
  res.send response_body(req.body)

# Start the server / web API
app.listen config.metrics.port, () ->
  console.log("-> Apocalypse Metrics Server ready on http://#{config.metrics.hostname}:#{config.metrics.port}")
