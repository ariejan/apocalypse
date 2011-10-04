var config = {};

// Available metrics to use
config.metrics = {};
config.metrics = ['cpu','memory','swap','disk_usage']

// HTTP Authentication credentials to be used by the clients
config.metrics.username = "example"
config.metrics.password = "example"

config.metrics.port = process.env.WEB_PORT || 3001;
config.metrics.hostname = "localhost";

// Reachability interval
config.reachability = {};
config.reachability.interval = 2000 // ms

// Client configuration
config.client     = {};
config.client.latest_version = "0.0.3"

// Result codes for clients
RESULT_OK               = 0
RESULT_CLIENT_OUTDATED  = 1001

// Dashboard configuration
config.dashboard = {};
config.dashboard.port = process.env.WEB_PORT || 3000;
config.dashboard.hostname = "localhost";

module.exports = config;
