require 'yaml'
require 'discordrb'
require_relative 'manager'

connection_config = YAML.load_file(File.join(__dir__, "config/connect.yaml"))
bot = Discordrb::Commands::CommandBot.new token: connection_config['token'], client_id: connection_config['client_id'], prefix: '!', help_command: false, ignore_bots: true

bot.ready do |event|
  bot.game = "with panties"
end

Manager.new(bot)

bot.run
