require 'yaml'
require 'active_record'

root = File.expand_path(File.dirname(__FILE__)).split('/')[0..-2].join('/')
config = YAML.load_file(File.join(root, "lib", "config", "database.yml"))["test"]
ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     config['host'],
  username: config['username'],
  password: config['password'],
  database: config['database']
)
