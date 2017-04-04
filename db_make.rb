# This assumes you've made the databases to allow you to modify the SQL user's permissions.
require 'yaml'
require 'mysql2'

base_dir = File.expand_path(File.dirname(__FILE__))
config_full = YAML.load_file(File.join(base_dir, "lib", "config", "db.yml"))

ARGV.each do |environment|
  next unless config.key? environment
  config = config_full[environment]
  db = Mysql2::Client.new(
    host:      config['host'],
    username:  config['username'],
    password:  config['password'],
    database:  config['database'],
    port:      config['port'],
    encoding:  "utf8mb4",
    reconnect: true,
  )

  db.query("DROP TABLE messages;")
  db.query("DROP TABLE members;")
  db.query("DROP TABLE roles;")

  db.query("CREATE TABLE IF NOT EXISTS messages (
    id BIGINT NOT NULL AUTO_INCREMENT,
    server_id BIGINT NOT NULL,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    message_id BIGINT NOT NULL,
    username VARCHAR(100) NOT NULL,
    content TEXT,
    attachments TEXT,
    PRIMARY KEY (id),
    CONSTRAINT unique_message_id UNIQUE (server_id, channel_id, message_id)
  );")
  db.query("CREATE TABLE IF NOT EXISTS members (
    id BIGINT NOT NULL AUTO_INCREMENT,
    server_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar VARCHAR(150),
    PRIMARY KEY (id),
    CONSTRAINT unique_user_id UNIQUE (server_id, user_id)
  );")
  db.query("CREATE TABLE IF NOT EXISTS roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    server_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role_id VARCHAR(100),
    PRIMARY KEY (id),
    CONSTRAINT unique_role UNIQUE (server_id, user_id, role_id)
  );")
end
