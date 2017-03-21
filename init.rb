require 'yaml'
require 'discordrb'

connection_config = YAML.load_file('config/connect.yaml')
help_messages = YAML.load_file('config/help_messages.yaml')

if File.exists? ('data/custom_commands.yaml')
  custom_commands = YAML.load_file('data/custom_commands.yaml')
else
  custom_commands = {}
end

bot = Discordrb::Commands::CommandBot.new token: connection_config['token'], client_id: connection_config['client_id'], prefix: '!', help_command: false, ignore_bots: true

bot.command(:addcom, required_permissions: [:manage_messages], usage: '!addcom <trigger> <output>', min_args: 2) do |event, trigger, output|
  if custom_commands[trigger]
    event.respond "`#{trigger}` already exists as a custom command. Maybe you meant to edit the current one?"
  end

  custom_commands[trigger] = output
  File.open('data/custom_commands.yaml', 'w') { |f| f.write custom_commands.to_yaml } # Save it to a YAML so it persists beyond single sessions

  event.respond "Custom command `#{trigger}` added successfully!"
end

bot.command(:delcom, required_permissions: [:manage_messages], usage: '!delcom <trigger>', min_args: 1) do |event, trigger|
  value = custom_commands.delete(trigger)
  if value.nil?
    event.respond "`#{trigger}` is not a custom command."
  else
    event.respond "`#{trigger}` custom command deleted."
  end
end

bot.command(:editcom, required_permissions: [:manage_messages], usage: '!editcom <trigger> <output>', min_args: 2) do |event, trigger, output|
  if custom_commands[trigger].nil?
    event.respond "`#{trigger} does not exist."
  end

  custom_commands[trigger] = output
  File.open('data/custom_commands.yaml', 'w') { |f| f.write custom_commands.to_yaml }

  event.respond "Custom command `#{trigger}` has been updated!"
end

bot.command(:listcom, usage: '!listcom', max_args: 0) do |event|
  output = "The currently registered custom commands are:\n```\n"
  custom_commands.keys.each do |key|
    output += "!#{key}\n"
  end
  output += "```"
  event.respond output
end

bot.run
