require 'mysql2'
require_relative 'manager'

# Requires the following commands to be run
#   CREATE DATABASE shimapan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
#   CREATE USER shimapan@localhost;
#   GRANT ALL PRIVILEGES ON shimapan.* TO shimapan@localhost;
#   FLUSH PRIVILEGES;
class Database
  # Opens up the database and prepares to write values in.
  def initialize
    db_config = YAML.load_file(File.join(Manager.root, "config", "db.yml"))[Manager.env]
    @@db = Mysql2::Client.new(
      host:      db_config['host'],
      username:  db_config['username'],
      password:  db_config['password'],
      database:  db_config['database'],
      encoding:  "utf8mb4",
      reconnect: true
    )

  end

  # Executes an SQL query.
  # @param query [String] The resolved Query object (done internally).
  def execute(query)
    begin
      puts "[EXECUTE] %s" % query
      @@db.query(query, symbolize_keys: true)
    rescue StandardError => e
      p e
    end
  end
end
