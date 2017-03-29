require 'sqlite3'

class Database
  # Opens up the database and prepares to write values in.
  def initialize
    @@db = SQLite3::Database.new(File.join(ENV['SHIMA_ROOT'], "data", "sqlite3.db"))

    @@db.execute("CREATE TABLE IF NOT EXISTS messages (
      id INT PRIMARY KEY,
      server_id INT NOT NULL,
      channel_id INT NOT NULL,
      user_id INT NOT NULL,
      message_id INT NOT NULL,
      username VARCHAR(100) NOT NULL,
      content TEXT,
      attachments TEXT
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS members (
      id INT PRIMARY KEY,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      display_name VARCHAR(100) NOT NULL,
      avatar VARCHAR(150)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS roles (
      id INT PRIMARY KEY,
      server_id INT NOT NULL,
      user_id INT NOT NULL,
      role VARCHAR(100)
    );")
  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    @@db.execute(query)
  end
end
