require 'sqlite3'

class Database
  # Opens up the database and prepares to write values in.
  def initialize
    @@db = SQLite3::Database.new("data/sqlite3.db")

    @@db.execute("CREATE TABLE IF NOT EXISTS messages (
      server_id INT,
      channel_id INT,
      user_id INT,
      username VARCHAR(100),
      content TEXT,
      attachment TEXT
    );")
    @@db.execute("CREATE TABLE IF NOT EXISTS members (
      server_id INT,
      user_id INT,
      avatar VARCHAR(150),
      roles TEXT
    );")
  end

  # Creates a new Query object and returns it.
  # @param table [String] The table name.
  # @option type [Symbol] The type of operation to perform on the table.
  def query(table, type = :select)
    require_relative 'datatype/query'
    Query.new(table, type)
  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    @@db.execute(query)
  end
end
