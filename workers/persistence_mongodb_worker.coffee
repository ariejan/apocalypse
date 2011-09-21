# This worker listens for incoming raw metrics and stores them in MongoDB for
# possible later usage.

# Configuration
global.config = require('../config')

name = "Persistance worker"
desc = "Store raw metrics in MongoDB"

# Require external libs
mongo    = require('mongoskin')
db       = mongo.db(config.mongodb.url)
redis    = require("redis")
client   = redis.createClient()

# Define our 'metrics' collection for Mongo
# server, timestamp, key, value
db.bind('metrics', {})
db.metrics.ensureIndex { hostid: 1 }, (err) ->
  if (err)
    console.log(err)

# Handle redis errors gracefully
client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err

# Handle messages
client.on "message", (channel, message) ->
  data = JSON.parse(message)
  db.metrics.insert { hostid: data.hostid, created_at: data.created_at, metrics: data.metrics }, (err) ->
    if (err)
      console.log "!! Error persisting to MongoDB: #{erro}"
    else
      console.log "-- Persisted raw data to MongoDB"

# Subscribe to the raw_metrics channel
client.subscribe "metrics"

console.log("== #{name} loaded.")
