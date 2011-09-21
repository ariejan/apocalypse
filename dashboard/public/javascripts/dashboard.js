var socket = io.connect('http://#{config.dashboard.hostname}');

function time_ago_in_words(from) {
  return distance_of_time_in_words(new Date().getTime(), from)
}

function distance_of_time_in_words(to, from) {
  seconds_ago = ((to  - from) / 1000);
  minutes_ago = Math.floor(seconds_ago / 60)

  if(minutes_ago == 0) { return "less than a minute";}
  if(minutes_ago == 1) { return "a minute";}
  if(minutes_ago < 45) { return minutes_ago + " minutes";}
  if(minutes_ago < 90) { return " about 1 hour";}
  hours_ago  = Math.round(minutes_ago / 60);
  if(minutes_ago < 1440) { return "about " + hours_ago + " hours";}
  if(minutes_ago < 2880) { return "1 day";}
  days_ago  = Math.round(minutes_ago / 1440);
  if(minutes_ago < 43200) { return days_ago + " days";}
  if(minutes_ago < 86400) { return "about 1 month";}
  months_ago  = Math.round(minutes_ago / 43200);
  if(minutes_ago < 525960) { return months_ago + " months";}
  if(minutes_ago < 1051920) { return "about 1 year";}
  years_ago  = Math.round(minutes_ago / 525960);
  return "over " + years_ago + " years"
}

$(document).ready(function() {

  var hostid_to_domid = function(hostid) {
    return hostid.replace(/\./g, "-");
  };

  var clear_hosts = function() {
    $('#hosts').find('tbody').empty();
  };

  var add_host = function(data) {
    $('#hosts').find('tbody')
    .append($("<tr>")
      .attr("id", hostid_to_domid(data.hostid))
      .append($("<td>")
        .attr("class", "hostid")
        .text(data.hostid)
      )
      .append($("<td>")
        .attr("class", "cpu unknown")
        .text("-")
      )
      .append($("<td>")
        .attr("class", "memory unknown")
        .text("-")
      )
      .append($("<td>")
        .attr("class", "disk unknown")
        .text("-")
      )
      .append($("<td>")
        .attr("class", "updated_at")
        .text("-")
      )
    )

    $.each(['cpu', 'memory', 'disk'], function(index, metric) {
      try {
        console.log(data.status[metric]['status']);
        update_dom_status(data.hostid, metric, data.status[metric]['status'], data.status[metric]['value'], new Date(data.status.updated_at));
      }
      catch (err) { console.log(err); }
    });
  };

  var update_dom_status = function(hostid, metric_type, status, value, updated_at) {
    dom_id = '#hosts > tbody > tr#'+hostid_to_domid(hostid)+' td.'+metric_type;
    $(dom_id).html(value);

    if (status == "alert") {
      $(dom_id).removeClass("unknown").removeClass("ok").addClass("alert");
    } else if (status == "ok") {
      $(dom_id).removeClass("unknown").removeClass("alert").addClass("ok");
    } else {
      $(dom_id).removeClass("ok").removeClass("alert").addClass("unknown");
    }

    dom_id = '#hosts > tbody > tr#'+hostid_to_domid(hostid)+' td.updated_at';
    $(dom_id).html(time_ago_in_words(updated_at) + " ago");
  }

  var update_status = function(data) {
    update_dom_status(data.hostid, data.metric_type, data.status, data.last_value, new Date());
  };

  socket.on('connect', function () {
    $('#connection_status').html("Connected to Apocalypse Server.");
  });

  socket.on('message', function (data) {
    data = JSON.parse(data);

    if (data.type == "host") {
      add_host(data);
    } else if (data.type == "clear") {
      clear_hosts();
    } else if (data.type == "status") {
      update_status(data);
    }
  });

  socket.on('disconnect', function () {
    $('#connection_status').html("Not connected to Apocalypse Server.");
  });
});
