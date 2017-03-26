require 'sqlite3'

class Database
  # Opens up the database and prepares to write values in.
  def initialize
    @@db = SQLite3::Database.new("data/sqlite3.db")

    @@db.execute("CREATE TABLE IF NOT EXISTS messages (
      server_id INT,
      channel_id INT,
      user_id INT,
      username VARCHAR(MAX),
      content VARCHAR(MAX),
      attachment VARCHAR(MAX)
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS members (
      server_id INT,
      user_id INT,
      avatar VARCHAR(MAX),
      roles VARCHAR(MAX)
    );")
  end

  def execute(query)
  end
end
