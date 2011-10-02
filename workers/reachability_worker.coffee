# This worker will ping hosts that we haven't heard of for more than 60
# seconds to see if they are still reachable. If not, a warning is
# issued.

global.config = require '../config'

name = "Reachability worker"
desc = "Check for host reachability"

# External libs
redis  = require "redis"

client = redis.createClient()

# Handle Redis errors
client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err

redis_key = "reachability"

# Check the next available host
checkNextHost = () ->
  host_id = null

  client.zrange redis_key, 0, 0, (err, data) ->
    if (data instanceof Array)
      host_id = data[0]

    if host_id
      console.log("Checking reachability on #{host_id}")
    else
      return

# Periodically (every second) check if a host needs checking
setInterval checkNextHost, config.reachability.interval
