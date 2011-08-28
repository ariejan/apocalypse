# Configuration
serverPort = process.env.PORT || 3000

# Require external libs
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
app.listen serverPort, () ->
  console.log("-> Apocalypse ready on http://0.0.0.0:#{serverPort}")
