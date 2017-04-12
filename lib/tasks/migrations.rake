require 'active_record_migrations'

ActiveRecordMigrations.configure do |c|
  c.yaml_config = "lib/config/database.yml"
  c.environment = ENV['ENV']
end

ActiveRecordMigrations.load_tasks
