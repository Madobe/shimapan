desc "Starts IRB with all the project files loaded"
task :console do
  require 'yaml'
  require 'active_record'

  ENV['ENV'] ||= 'development'
  config = YAML.load_file(File.join(Dir.pwd, "lib", "config", "database.yml"))[ENV['ENV']]
  ActiveRecord::Base.establish_connection(
    adapter:  'mysql2',
    host:     config['host'],
    username: config['username'],
    password: config['password'],
    database: config['database']
  )

  $:.unshift(Dir.pwd)
  Dir["lib/**/*.rb"].each { |file| require file }
  Manager::Base.start(false)
  require 'irb'
  ARGV.clear
  IRB.start
end
