var config        = {};
config.metrics    = {};
config.dashboard  = {};
config.client     = {};

config.metrics = ['cpu','memory','swap','disk_usage']

// HTTP Authentication credentials to be used by the clients
config.metrics.username = "example"
config.metrics.password = "example"

config.dashboard.port = process.env.WEB_PORT || 3000;
config.dashboard.hostname = "localhost";

config.metrics.port = process.env.WEB_PORT || 3001;
config.metrics.hostname = "localhost";

module.exports = config;

config.client.latest_version = "0.0.3"

// Result codes for clients
RESULT_OK               = 0
RESULT_CLIENT_OUTDATED  = 1001