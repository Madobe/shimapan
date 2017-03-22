require 'yaml'
require 'discordrb'
require 'thread'

require_relative 'modules/file_management'
require_relative 'modules/utilities'

require_relative 'commands'

connection_config = YAML.load_file('config/connect.yaml')
help_messages = YAML.load_file('config/help_messages.yaml')

# Custom commands are saved in a YAML file to allow them to persist
if File.exists? ('data/custom_commands.yaml')
  custom_commands = YAML.load_file('data/custom_commands.yaml')
else
  custom_commands = {}
end
custom_commands.extend FileManagement::CustomCommands

bot = Discordrb::Commands::CommandBot.new token: connection_config['token'], client_id: connection_config['client_id'], prefix: '!', help_command: false, ignore_bots: true

Commands.setup(bot)

bot.run
