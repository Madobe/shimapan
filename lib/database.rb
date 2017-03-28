require 'sqlite3'

class Database
  # Opens up the database and prepares to write values in.
  def initialize
    @@db = SQLite3::Database.new("data/sqlite3.db")

    @@db.execute("CREATE TABLE IF NOT EXISTS messages (
      id INT NOT NULL PRIMARY KEY,
      server_id INT NOT NULL,
      channel_id INT NOT NULL,
      user_id INT NOT NULL,
      message_id INT NOT NULL,
      username VARCHAR(100) NOT NULL,
      content TEXT,
      attachment TEXT,
      CONSTRAINT unique_message UNIQUE (server_id, channel_id, message_id)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS members (
      id INT NOT NULL PRIMARY KEY,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      display_name VARCHAR(100) NOT NULL,
      avatar VARCHAR(150),
      CONSTRAINT unique_member UNIQUE (server_id, user_id)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS roles (
      id INT NOT NULL PRIMARY KEY,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      role VARCHAR(100),
      CONSTRAINT unique_member_role UNIQUE (server_id, user_id, role)
    );")
  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    @@db.execute(query)
  end
end
