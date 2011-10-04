$ ->
  socket = io.connect()

  time_ago_in_words = (from) ->
    if from != null
      return distance_of_time_in_words(new Date().getTime(), from)
    else
      return "-"

  distance_of_time_in_words = (to, from) ->
    seconds = ((to  - from) / 1000)

    # Make sure we don't show negative times, it's stupid
    if seconds < 0
      seconds = 0

    if seconds == 0
      return "now"
    else
      result = ""

      d = Math.floor(seconds / 86400)
      seconds -= d * 86400
      result += "#{d}d" unless d == 0

      h = Math.floor(seconds / 3600)
      seconds -= h * 3600
      result += "#{h}h" unless h == 0

      m = Math.floor(seconds / 60)
      seconds -= m * 60
      result += "#{m}m" unless m == 0

      s = Math.floor(seconds)
      result += "#{s}s" unless s == 0



  hostid_to_domid = (hostid) ->
    return hostid.replace(/\./g, "-")

  clear_hosts = () ->
    $('#hosts').find('tbody').empty()

  add_host = (data) ->
    $('#hosts').find('tbody')
      .append $("<tr>")
        .attr("id", hostid_to_domid(data.hostid))
        .append($("<td>").attr("class", "hostid").text(data.hostid))
        .append($("<td>").attr("class", "latency unknown"))
        .append($("<td>").attr("class", "cpu unknown"))
        .append($("<td>").attr("class", "memory unknown"))
        .append($("<td>").attr("class", "swap unknown"))
        .append($("<td>").attr("class", "disk_usage unknown"))
        .append($("<td>").attr("class", "updated_at unknown"))

  update_disk_usage_dom_status = (hostid, status, value, mount, device, updated_at) ->
    parent_dom_id = '#hosts > tbody > tr#'+hostid_to_domid(hostid)+' td.disk_usage'
    dom_id = '#hosts > tbody > tr#'+hostid_to_domid(hostid)+' td.disk_usage > span#'+device

    if (value == null)
      return

    # 43% /home
    the_text = '' + value + '% '+mount

    if ($(dom_id).length > 0)
      # update
      $(dom_id).html(the_text)
      if (status == "alert")
        $(dom_id).removeClass("unknown").removeClass("ok").addClass("alert")
      else if (status == "ok")
        $(dom_id).removeClass("unknown").removeClass("alert").addClass("ok")
      else
        $(dom_id).removeClass("ok").removeClass("alert").addClass("unknown")
    else
      # create
      $(parent_dom_id).append($('<span>')
        .attr('id', device)
        .attr('class', status)
        .text(the_text)
      )

  update_dom_status = (hostid, metric_type, status, value, updated_at) ->
    dom_id = '#hosts > tbody > tr#'+hostid_to_domid(hostid)+' td.'+metric_type

    # Do some special stuff for updated_at times
    if metric_type == "updated_at"
      $(dom_id).data('updated-at', new Date(value).getTime())
      value = time_ago_in_words(new Date(value).getTime())

    # Set current value
    $(dom_id).html(value)

    if (status == "alert")
      $(dom_id).removeClass("unknown").removeClass("ok").addClass("alert")
    else if (status == "ok")
      $(dom_id).removeClass("unknown").removeClass("alert").addClass("ok")
    else
      $(dom_id).removeClass("ok").removeClass("alert").addClass("unknown")

  update_status = (data) ->
    if (data.metric_type == "disk_usage")
      # Handle different mount points correctly
      update_disk_usage_dom_status(data.hostid, data.status, data.last_value, data.mount, data.device, data.updated_at)
    else
      update_dom_status(data.hostid, data.metric_type, data.status, data.last_value, data.updated_at)

  socket.on 'connect', () ->
    $('#connection_status span').html("Connected to Apocalypse Server.")

  socket.on 'message', (data) ->
    data = JSON.parse(data)

    # Host presence
    if (data.type == "host")
      add_host(data)
    # Clear hosts
    else if (data.type == "clear")
      clear_hosts()
    # Status update for a specific metric
    else if (data.type == "status")
      update_status(data)

  socket.on 'disconnect', () ->
    $('#connection_status span').html("Not connected to Apocalypse Server.")

  ## Auto updates the updated-at times
  tick = () ->
    dom_id = '#hosts td.updated_at'

    $(dom_id).each (i, elem) ->
      if $(elem).data('updated-at')
        $(elem).html(distance_of_time_in_words(new Date().getTime(), $(elem).data('updated-at')))
    setTimeout(tick, 2000)

  tick()
