# This worker keeps a 'most recent status' overview in Redis. This speeds up the
# loading of the initial Dashboard page.

# Configuration
global.config = require('../config')

name = "Redis Persistance worker"
desc = "Store the most actual status in Redis"

# Require external libs
redis       = require("redis")
status_client = redis.createClient()
data_client   = redis.createClient()

# Handle redis errors gracefully
status_client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err
data_client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err

# Handle messages
status_client.on "message", (channel, message) ->
  data = JSON.parse(message)

  # Add the hostid to our complete set of hostids
  data_client.sadd 'hostids', data.hostid

  # Store this message
  data_client.hset "host:#{data.hostid}:messages", data.message_id, message
  console.log "Persisted host:#{data.hostid}:messages -> #{data.message_id}"

# Subscribe to the status channel
status_client.subscribe "status"

console.log("== #{name} loaded.")
