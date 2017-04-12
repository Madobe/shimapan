require 'rake/testtask'

task default: :test

desc "Run all unit tests"
task test: "test:regular"

Rake::TestTask.new("test:regular") do |t|
  t.libs << "spec" << "lib" << "."
  t.pattern = "spec/**/*_test.rb"
  t.warning = false
  t.verbose = true
end
