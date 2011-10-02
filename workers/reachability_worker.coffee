# This worker will ping hosts that we haven't heard of for more than 60
# seconds to see if they are still reachable. If not, a warning is
# issued.

global.config = require '../config'

name = "Reachability worker"
desc = "Check for host reachability"

# External libs
redis  = require "redis"
client = redis.createClient()

sys    = require "sys"
exec   = require("child_process").exec

# Handle Redis errors
client.on "error", (err) ->
  console.log "Redis error (#{name}): " + err

redis_key = "reachability"

ping = (count, hostname, callback) ->
  exec "ping -c #{count} #{hostname}", (err, stdout, stderr) ->
    if err
      msg = null

      if stderr && stderr.length > 0
        msg = stderr.replace(/\n/,'').match(/.*\:(.*)/)[1]
      else
        lines = stdout.split('\n')
        msg = lines[lines.length - 3]

      callback({success: false, errmsg: msg})

    else
      lines = stdout.split('\n')
      for line in lines
        do (line) ->
          matches = line.match(/^(rtt|round-trip).*=\ (\d+\.\d+)\/(\d+\.\d+)\/(\d+\.\d+)\/(\d+\.\d+).*/)
          if matches #&& matches.length == 5
            callback({
              success: true,
              data: {
                min: parseInt(matches[2]),
                avg: parseInt(matches[3]),
                max: parseInt(matches[4]),
                mdev: parseInt(matches[5])
              }
            })

# Check the next available host
checkNextHost = () ->
  host_id = null

  client.zrange redis_key, 0, 0, 'withscores', (err, data) ->
    if (data instanceof Array)
      host_id = data[0]
      last_check = data[1]
      delta = (new Date().getTime() - last_check) / 1000.0

      if delta <= config.reachability.frequency
        console.log "Skipping check; already performed #{delta} seconds ago"

        # Reschedule with a delay
        setTimeout checkNextHost, config.reachability.delay
        return

    if host_id
      console.log("Checking reachability on #{host_id}")
      ping 3, host_id, (data) ->
        if data.success
          console.log "OK - avg #{data.data.avg}ms"
        else
          console.log "NOT OK - #{data.errmsg}"

        # Update reachability score
        client.zadd redis_key, new Date().getTime(), host_id

        # Reschedule, immediately
        setTimeout checkNextHost, 0
        return
    else
      # Reschedule with some delay
      setTimeout checkNextHost, config.reachability.delay
      return


# Trigger the initial checkNextHost
checkNextHost()
