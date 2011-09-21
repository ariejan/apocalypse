# This worker analyses disk usage (space) and
# report the results to the alerts channel

# Configuration
global.config = require('../config')

name = "Disk Usage Analyser"
desc = "Analyse disk usage"

# If disk usage, for any disk, is > 90% we'll give an alert
threshold_value = 90

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
    list     = "#{hostid}_disk_usage"

    disk_usage = []

    for blockdevice in data.load.blockdevices
      for device, info of blockdevice
        if info.mount != null
          disk_usage = parseInt(info.usage.replace(/%/g,""))

          # Create the alert message
          alert_message =
            hostid: hostid
            status: if disk_usage >= threshold_value then "alert" else "ok"
            metric_type: "disk_usage"
            type: 'status'
            last_value: disk_usage
            mount: info.mount
            device: device

          # Post the alert message to the alerts channel
          console.log "Disk usage for #{hostid} on '#{info.mount}': #{disk_usage}"
          data_client.publish "status", JSON.stringify(alert_message)

  catch error
    console.log "!! Error processing disk_usage data: #{error}"


# Subscribe to the raw_metrics channel
client.subscribe "metrics"

console.log("== #{name} loaded.")

