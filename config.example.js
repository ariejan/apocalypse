var config = {};

config.metrics = {};
config.dashboard = {};

config.metrics = ['cpu','memory','swap','disk_usage']

// HTTP Authentication credentials to be used by the clients
config.metrics.username = "example"
config.metrics.password = "example"

// config.mongodb.url = process.env.MONGODB_URL || "mongo://localhost/apocalypse_dev"

config.dashboard.port = process.env.WEB_PORT || 3000;
config.dashboard.hostname = "localhost";

config.metrics.port = process.env.WEB_PORT || 3001;
config.metrics.hostname = "localhost";

module.exports = config;

