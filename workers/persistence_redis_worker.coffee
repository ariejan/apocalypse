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

  # Update the current host_id status
  status_key = "host:#{data.hostid}:status"

  data_client.set "host:#{data.hostid}:latest:#{data.metric_type}:updated_at", new Date()
  data_client.set "host:#{data.hostid}:latest:#{data.metric_type}:status", data.status
  data_client.set "host:#{data.hostid}:latest:#{data.metric_type}:value", data.last_value

  console.log "Persisted host:#{data.hostid}:latest:#{data.metric_type}:status => #{data.status}"
  console.log "Persisted host:#{data.hostid}:latest:#{data.metric_type}:value => #{data.last_value}"

  # Presist more for disk_usage
  if data.mount
    data_client.set "host:#{data.hostid}:latest:#{data.metric_type}:mount", data.mount
    data_client.set "host:#{data.hostid}:latest:#{data.metric_type}:device", data.device
    console.log "Persisted host:#{data.hostid}:latest:#{data.metric_type}:mount => #{data.mount}"
    console.log "Persisted host:#{data.hostid}:latest:#{data.metric_type}:device => #{data.device}"


# Subscribe to the status channel
status_client.subscribe "status"

console.log("== #{name} loaded.")
