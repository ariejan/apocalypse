# Configuration
global.config = require('../config')

# Require external libs, including
# Express for HTTP and
# socket.io for Websockets
sys      = require('sys')
express  = require('express')
socketio = require('socket.io')
app      = express.createServer()
io       = socketio.listen(app)


############################################
#### Redis
############################################
redis           = require("redis")
client          = redis.createClient()
io_client       = redis.createClient()

# Handle redis errors gracefully
client.on "ready", () ->
  console.log "== Redis reporting for duty."

client.on "error", (err) ->
  console.log "!! Redis error: " + err


############################################
#### Worker plugins
############################################

workers = [
  "persistence",
  "cpu"
]
workers.forEach (worker) ->
  require "./workers/#{worker}_worker"



############################################
#### Websockets
############################################

# Join the "alerts" channel when connecting
# with your websocket
io.sockets.on "connection", (socket) ->
  subscribe = redis.createClient()
  subscribe.subscribe "alerts"

  subscribe.on "message", (channel, message) ->
    socket.send(message)

  socket.on "disconnect", () ->
    subscribe.quit()

############################################
#### Express / API
############################################

# Some Express setup
app.configure () ->
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.errorHandler(
    dumpExceptions: true,
    showStack: true
  )
  app.set('view engine', 'jade');

# GET /
# Show the alerts dashboard
app.get '/', (req, res) ->
  res.render('index')

# POST /api/metrics
# Store recorded metrics data
app.post '/api/metrics/:hostid', (req, res) ->
  metric_data =
    hostid:     req.params.hostid,
    metrics:    req.body,
    created_at: new Date()

  client.publish "raw_metrics", JSON.stringify(metric_data)
  res.send { status: 'OK' }

# Start the server / web API
app.listen config.web.port, () ->
  console.log("-> Apocalypse ready on http://0.0.0.0:#{config.web.port}")
