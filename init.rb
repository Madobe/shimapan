require 'yaml'
require 'discordrb'

require_relative 'modules/file_management'

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

# Kicks the mentioned user out of the server.
# @param user [String] Must be a mention or ID.
bot.command(:kick, required_permissions: [:kick_members], usage: '!kick <user>', min_args: 1) do |event, user|
  user_id = user.gsub(/\D/, '')
  event.server.kick(user_id)
end

# Bans the mentioned user from the server.
# @param user [String] Must be a mention or ID.
bot.command(:ban, required_permissions: [:ban_members], usage: '!ban <user>', min_args: 1) do |event, user|
  user_id = user.gsub(/\D/, '')
  event.server.ban(user_id)
end

# Unbans the mentioned user from the server.
# @param user [String] Must be a mention or ID.
bot.command(:unban, required_permissions: [:ban_members], usage: '!unban <user>', min_args: 1) do |event, user|
  user_id = user.gsub(/\D/, '')
  event.server.unban(user_id)
end

# Add a custom command.
# @param trigger [string] the custom command trigger.
# @param output [string] the output of the custom command.
bot.command(:addcom, required_permissions: [:manage_messages], usage: '!addcom <trigger> <output>', min_args: 2) do |event, trigger, output|
  if custom_commands[trigger]
    event.respond "`#{trigger}` already exists as a custom command. maybe you meant to edit the current one?"
  end

  custom_commands.update(trigger, output)

  # Actually make the command work now
  bot.command(trigger.to_sym, usage: "!#{trigger}", max_args: 0) do |event|
    event.respond output
  end

  event.respond "Custom command `#{trigger}` added successfully!"
end

# Deletes an existing custom command.
# @param trigger [String] The trigger of the custom command to delete.
bot.command(:delcom, required_permissions: [:manage_messages], usage: '!delcom <trigger>', min_args: 1) do |event, trigger|
  value = custom_commands.delete(trigger)
  if value.nil?
    event.respond "`#{trigger}` is not a custom command."
  else
    bot.remove_command trigger.to_sym
    custom_commands.update
    event.respond "`#{trigger}` custom command deleted."
  end
end

# Edits an already existing custom command.
# @param trigger [String] The custom command trigger.
# @param output [String] The output of the custom command.
bot.command(:editcom, required_permissions: [:manage_messages], usage: '!editcom <trigger> <output>', min_args: 2) do |event, trigger, output|
  if custom_commands[trigger].nil?
    event.respond "`#{trigger} does not exist."
  end

  custom_commands.update(trigger, output)

  event.respond "Custom command `#{trigger}` has been updated!"
end

# Lists all currently existing custom commands.
bot.command(:listcom, usage: '!listcom', max_args: 0) do |event|
  output = "The currently registered custom commands are:\n```\n"
  custom_commands.keys.sort.each do |key|
    output += "!#{key}\n"
  end
  output += "```"
  event.respond output
end

custom_commands.keys.each do |key|
  bot.command(key.to_sym, usage: "!#{key}", max_args: 0) do |event|
    event.respond custom_commands[key]
  end
end

bot.run
