require 'sqlite3'

class Database
  # Opens up the database and prepares to write values in.
  def initialize
    @@db = SQLite3::Database.new(File.join(ENV['SHIMA_ROOT'], "data", "sqlite3.db"))

    @@db.execute("CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id INT NOT NULL,
      channel_id INT NOT NULL,
      user_id INT NOT NULL,
      message_id INT NOT NULL,
      username VARCHAR(100) NOT NULL,
      content TEXT,
      attachments TEXT,
      CONSTRAINT unique_message_id UNIQUE (server_id, channel_id, message_id)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      display_name VARCHAR(100) NOT NULL,
      avatar VARCHAR(150),
      CONSTRAINT unique_user_id UNIQUE (server_id, user_id)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      role_id VARCHAR(100),
      CONSTRAINT unique_role UNIQUE (server_id, user_id, role_id)
    );")
  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    @@db.execute(query)
  end
end
