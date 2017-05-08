namespace :shimapan do
  namespace :run do
    desc "Runs shimapan in production mode"
    task :production do
      ENV['ENV'] = "production"
      start_shimapan
    end

    desc "Runs shimapan in development mode"
    task :development do
      ENV['ENV'] = "development"
      start_shimapan
    end

    def start_shimapan
      require 'lib/manager/base'
      require 'lib/manager/command'
      require 'lib/manager/log'

      Manager::Base.start(true)
      Manager::Commands.new
      Manager::Logs.new
      #Manager::Music.new # Keep this on development for now
      Manager::Base.sync
    end
  end

  desc "Runs shimapan in development mode"
  task :run do
    Rake::Task['shimapan:run:development'].invoke
  end

  namespace :restart do
    desc "Restarts shimapan in production mode"
    task :production do
      ENV['ENV'] = "production"
      Rake::Task['shimapan:stop'].invoke
      Rake::Task['shimapan:run:production'].invoke
    end

    desc "Restarts shimapan in development mode"
    task :development do
      ENV['ENV'] = "development"
      Rake::Task['shimapan:stop'].invoke
      Rake::Task['shimapan:run:development'].invoke
    end
  end

  desc "Restarts shimapan in development mode"
  task :restart do
    Rake::Task['shimapan:restart:development'].invoke
  end

  desc "Stops shimapan by sending a SIGTERM"
  task :stop do
    Process.kill("TERM", File.read('/var/run/shimapan/shimapan.pid').to_i) if File.exists?('/var/run/shimapan/shimapan.pid')
  end
end
