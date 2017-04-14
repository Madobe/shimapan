desc "Starts IRB with all the project files loaded"
task :console do
  require 'yaml'
  require 'active_record'

  config = YAML.load_file(File.join(Dir.pwd, "lib", "config", "database.yml"))[ENV['ENV'] || 'development']
  ActiveRecord::Base.establish_connection(
    adapter:  'mysql2',
    host:     config['host'],
    username: config['username'],
    password: config['password'],
    database: config['database']
  )

  $:.unshift(Dir.pwd)
  Dir["lib/**/*.rb"].each { |file| require file }
  require 'irb'
  ARGV.clear
  IRB.start
end
