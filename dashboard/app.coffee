# This is the Dashboard Server

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
  console.log "Dashboard server connected to redis"

client.on "error", (err) ->
  console.log "Dashbaord server could not connect to redis: " + err


############################################
#### Websockets
############################################

# Message to clear all hosts
clear_hosts = (websocket) ->
  websocket.send(JSON.stringify(type: 'clear'))

# Update a specific metric for a specific hostid
update_metric = (websocket, hostid, metric) ->
  multi = client.multi()
  multi.get "host:#{hostid}:latest:#{metric}:updated_at"
  multi.get "host:#{hostid}:latest:#{metric}:status"
  multi.get "host:#{hostid}:latest:#{metric}:value"

  if metric == "disk_usage"
    multi.get "host:#{hostid}:latest:#{metric}:mount"
    multi.get "host:#{hostid}:latest:#{metric}:device"

  multi.exec (err, replies) ->
    console.log(replies)

    message =
      hostid: hostid,
      type: 'status',
      metric_type: metric,
      status: replies[1],
      last_value: replies[2],
      updated_at: replies[0]

    if metric == "disk_usage"
      message['mount'] = replies[3]
      message['device'] = replies[4]

    websocket.send(JSON.stringify(message))


# Send a host update
update_host = (websocket, hostid) ->
  websocket.send(JSON.stringify(type: 'host', hostid: hostid))
  for metric in config.metrics
    update_metric(websocket, hostid, metric)

# Join the "alerts" channel when connecting
# with your websocket
io.sockets.on "connection", (websocket) ->
  subscribe = redis.createClient()
  subscribe.subscribe "status"

  # Upon connect, clear the current host table
  # and re-send all the current data we have
  client.smembers "hostids", (err, hostids) ->
    clear_hosts(websocket)
    for hostid in hostids
      update_host(websocket, hostid)

  # Respond to messages on the status channel
  subscribe.on "message", (channel, message) ->
    message = JSON.parse(message)
    websocket.send(JSON.stringify(message))

  # Disconnect from `status` channel when the websocket is closed
  websocket.on "disconnect", () ->
    subscribe.quit()

############################################
#### Express / API
############################################

# Some Express setup
app.configure () ->
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.static(__dirname + '/public'));
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.errorHandler(
    dumpExceptions: true,
    showStack: true
  )

# GET /
# Show the alerts dashboard
app.get '/', (req, res) ->
  res.render('index')

# Start the server / web API
app.listen config.dashboard.port, () ->
  console.log("-> Apocalypse Dashboard Server ready on http://#{config.dashboard.hostname}:#{config.dashboard.port}")
