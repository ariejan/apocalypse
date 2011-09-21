# This worker analyses recent CPU usage and will
# report the results to the alerts channel

# Configuration
global.config = require('../config')

name = "Memory Analyzer worker"
desc = "Analyse Memory utilisation"

# If memory usage was 98% or more 4 out of the last 5 times, raise the alarm
threshold_value = 98
threshold_span  = 4
values_to_keep  = 5

# Require external libs
sys         = require('sys')
redis       = require("redis")
client      = redis.createClient()
data_client = redis.createClient()

# Handle redis errors gracefully
client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err

# Handle incoming raw_metrics messages
client.on "message", (channel, message) ->
  try
    # Get all the data we need
    data     = JSON.parse(message)
    hostid   = data.hostid
    list     = "#{hostid}_memory_avg"

    mem_total = parseInt data.load.memory.total
    mem_free  = parseInt data.load.memory.free

    # Percentage memory utilisation
    mem_usage = Math.round((((mem_total - mem_free) / mem_total) * 100) * 10) / 10

    # Store the data in redis, trim the list
    data_client.lpush list, mem_usage
    data_client.ltrim list, 0, values_to_keep-1

    # Get the lastest metrics, and determine what our status is
    data_client.lrange list, 0, values_to_keep-1, (err, values) ->
      # What's our status-score?
      score = (i for i in values when i >= threshold_value).length

      # Create the alert message
      alert_message = 
        hostid: hostid
        message_id: "memory"
        status: if score >= threshold_span then "alert" else "ok"
        metric_type: "memory"
        type: 'status'
        last_value: mem_usage

      console.log "Memory usage for #{hostid}: #{mem_usage}"

      # Post the alert message to the alerts channel
      data_client.publish "status", JSON.stringify(alert_message)
  catch error
    console.log "!! Error processing Memory data: #{error}"


# Subscribe to the raw_metrics channel
client.subscribe "metrics"

console.log("== #{name} loaded.")
