require 'mysql2'

# Requires the following commands to be run
#   CREATE DATABASE shimapan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
#   CREATE USER shimapan@localhost;
#   GRANT ALL PRIVILEGES ON shimapan.* TO shimapan@localhost;
#   FLUSH PRIVILEGES;
class Database
  # Opens up the database and prepares to write values in.
  def initialize
    #@@db = SQLite3::Database.new(File.join(ENV['SHIMA_ROOT'], "data", "sqlite3.db"))
    @@db = Mysql2::Client.new(
      host:      "localhost",
      username:  "shimapan",
      database:  "shimapan",
      encoding:  "utf8mb4",
      reconnect: true
    )

    @@db.query("CREATE TABLE IF NOT EXISTS messages (
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
    @@db.query("CREATE TABLE IF NOT EXISTS members (
      id BIGINT NOT NULL AUTO_INCREMENT,
      server_id BIGINT NOT NULL,
      user_id BIGINT NOT NULL,
      display_name VARCHAR(100) NOT NULL,
      avatar VARCHAR(150),
      PRIMARY KEY (id),
      CONSTRAINT unique_user_id UNIQUE (server_id, user_id)
    );")
    @@db.query("CREATE TABLE IF NOT EXISTS roles (
      id BIGINT NOT NULL AUTO_INCREMENT,
      server_id BIGINT NOT NULL,
      user_id BIGINT NOT NULL,
      role_id VARCHAR(100),
      PRIMARY KEY (id),
      CONSTRAINT unique_role UNIQUE (server_id, user_id, role_id)
    );")
  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    begin
      puts "[EXECUTE] %s" % query
      @@db.query(query, symbolize_keys: true)
    rescue Exception => e
      p e
    end
  end
end
