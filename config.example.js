var config = {}

config.mongodb = {};
config.web = {};

config.mongodb.url  = process.env.MONGODB_URL || "mongo://localhost/apocalypse_dev"
config.web.port     = process.env.WEB_PORT || 9980;
config.web.hostname = "apocalypse.example.org";

module.exports = config;
