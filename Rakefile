require 'bundler/setup'
require 'rake/testtask'
require 'active_record_migrations'

$:.unshift File.dirname(__FILE__)

task default: :test

desc "Run all unit tests"
task test: "test:regular"

Rake::TestTask.new("test:regular") do |t|
  t.libs << "spec" << "lib" << "."
  t.pattern = "spec/**/*_test.rb"
  t.warning = false
  t.verbose = false
end

namespace :shimapan do
  task :run do
    ruby 
  end

  task :stop do
  end
end

ActiveRecordMigrations.configure do |c|
  c.yaml_config = "lib/config/database.yml"
  c.environment = ENV['ENV']
end

ActiveRecordMigrations.load_tasks
