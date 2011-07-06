# Configuration
mongodbUrl = "mongo://localhost/apocalypse_dev"
serverPort = process.env.PORT || 3000

# Require external libs
yaml     = require('yaml')
express  = require('express')
app      = express.createServer()
mongo    = require('mongoskin')
db       = mongo.db(mongodbUrl)

# Some Express setup
app.configure () ->
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.errorHandler(
    dumpExceptions: true,
    showStack: true
  )

# Define our 'metrics' collection
# server, timestamp, key, value
db.bind('metrics', {})
db.metrics.ensureIndex { hostid: 1 }, (err) ->
  if (err)
    console.log(err)

# POST /api/metrics
# Store recorded metrics data
app.post '/api/metrics/:hostid', (req, res) ->
  metrics = req.body
  createdAt = new Date()

  db.metrics.insert { hostid: req.params.hostid, created_at: createdAt, metrics: metrics }, (err) ->
    if (err)
      res.send { status: 'failed' }
    else
      res.send { status: 'OK' }

app.listen serverPort, () ->
  console.log("Apocalypse ready on http://0.0.0.0:#{serverPort}")
