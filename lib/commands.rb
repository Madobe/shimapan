require 'yaml'
require 'fileutils'

require_relative 'manager'
require_relative 'modules/utilities'
require_relative 'datatype/query'

class CommandsManager
  # Initialize the settings variables and variables, then call to add all commands to the bot.
  def initialize
    @@save_location = File.join(ENV['SHIMA_ROOT'], 'data', 'custom_commands.yaml')
    @@help_messages = YAML.load_file(File.join(ENV['SHIMA_ROOT'], 'config', 'help_messages.yaml'))

    unless File.dirname('data')
      FileUtils.mkdir_p('data')
    end

    begin
      @@commands = YAML.load_file(@@save_location)
    rescue
      @@commands ||= {}
    end

    add_base_commands
    add_custom_commands
  end

  # Saves the YAML file.
  def save
    File.open(@@save_location, 'w') { |f| f.write @@commands.to_yaml }
  end

  # Adds the commands that are on the bot by default.
  def add_base_commands
    # Brings up the help documentation.
    # @option command [String] Provides help for specific commands if provided.
    Manager.bot.command(:help) do |event, command|
      if command.nil?
        output = "```Brings up this help documentation if not provided with a command. Brings up detailed documentation for a command if given one, if available.\nSyntax: !help <command>\nExample: !help listcom\n\nList of commands:"
        @@help_messages.keys.each do |trigger|
          output += "\n!#{trigger}"
        end
        output += "```"
        event.respond output
      elsif @@help_messages[command].nil?
        event.respond "No documentation available for this command."
      else
        event.respond @@help_messages[command]['message']
      end
    end

    # Adds an entry to the absence-log channel for the invoker. Usable only on Aramis.
    Manager.bot.command(:applyforabsence) do |event, *args|
      return event.respond "This command is only available on the Aramis Clan Server." if event.server.id != 262806098099044365
      channel = event.server.text_channels.find { |x| x.name == "absence-log" }
      reason = if args.size == 0 then "No reason given" else args.join(' ') end
      channel.send_message "[%s] %s\nReason: %s" % [Time.new.utc.strftime("%Y/%m/%d %H:%M:%S"), event.author.mention, reason]
      event.respond "Your application for an extended absence has been logged."
    end

    # Finds the given role on the server and returns its ID.
    # @param role [String] The name of the role to find.
    Manager.bot.command(:role, required_permissions: [:manage_roles], usage: '!role <role>', min_args: 1) do |event, *role|
      role = event.server.roles.find { |x| x.name == role.join(' ') }
      return event.respond "Role does not exist." if role.nil?
      event.respond role.id
    end

    # Mutes the mentioned user for the specified amount of time.
    # @param user [String] Must be a mention or ID.
    # @param time [String] Parsed as seconds unless there's a time unit behind it.
    Manager.bot.command(:mute, required_permissions: [:manage_roles], usage: '!mute <user> for <time> for <reason>', min_args: 1) do |event, *args|
      temp_add_role(event, args, "Mute", "mute", "muted")
    end

    # Unmutes the mentioned user.
    # @param user [User] A user mention. Must be a mention or it won't work.
    Manager.bot.command(:unmute, required_permissions: [:manage_roles], usage: '!unmute <user>', min_args: 1) do |event|
      remove_role(event, "Muted", "unmuted")
    end

    # Punishes the mentioned user.
    # @param user [User] A user mention. Must be a mention or it won't work.
    # @param time [String] Parsed as seconds unless there's a time unit behind it.
    Manager.bot.command(:punish, required_permissions: [:manage_roles], usage: '!punish <user> for <time>', min_args: 1) do |event, *args|
      temp_add_role(event, args, "Shitpost", "punish", "punished")
    end

    # Unpunishes the mentioned user.
    # @param user [User] A user mention. Must be a mention or it won't work.
    Manager.bot.command(:unpunish, required_permissions: [:manage_roles], usage: '!unpunish <user>', min_args: 1) do |event|
      remove_role(event, "Shitpost", "unpunished")
    end

    # Kicks the mentioned user out of the server.
    # @param user [String] Must be a mention.
    Manager.bot.command(:kick, required_permissions: [:kick_members], usage: '!kick <user>', min_args: 1) do |event|
      user = event.message.mentions.first
      return event.respond "No user was mentioned in the message." if user.nil?
      event.server.kick(user)
      event.respond "#{user.mention} was kicked from the server."
    end

    # Bans the mentioned user from the server.
    # @param user [String] Must be a mention.
    Manager.bot.command(:ban, required_permissions: [:ban_members], usage: '!ban <user>', min_args: 1) do |event|
      user = event.message.mentions.first
      return event.respond "No user was mentioned in the message." if user.nil?
      event.server.ban(user)
      event.respond "#{user.mention} was banned from the server."
    end

    # Unbans the mentioned user from the server.
    # @param user [String] Must be an ID.
    Manager.bot.command(:unban, required_permissions: [:ban_members], usage: '!unban <user>', min_args: 1) do |event, user|
      event.server.unban(user)
      event.respond "<@#{user}> was unbanned from the server."
    end

    # Adds a custom command for this server.
    # @param trigger [String] The trigger phrase for the custom command.
    # @param output [String] The bot's response to the trigger.
    Manager.bot.command(:addcom, required_permissions: [:manage_messages], usage: '!addcom <trigger> <output>', min_args: 2) do |event, trigger, output|
      @@commands[event.server.id] ||= {}
      @@commands[event.server.id][trigger] = output
      save
      event.respond "`#{trigger}` has been added."
    end

    # Deletes a custom command for this server.
    # @param trigger [String] The trigger phrase for the custom command.
    Manager.bot.command(:delcom, required_permissions: [:manage_messages], usage: '!delcom <trigger>', min_args: 1) do |event, trigger|
      @@commands[event.server.id] ||= {}
      @@commands[event.server.id].delete(trigger)
      save
      event.respond "`#{trigger}` has been deleted."
    end

    # Edits a currently existing custom command for this server.
    # @param trigger [String] The trigger phrase for the custom command.
    # @param output [String] The bot's response to the trigger.
    Manager.bot.command(:editcom, required_permissions: [:manage_messages], usage: '!editcom <trigger> <output>', min_args: 2) do |event, trigger, output|
      @@commands[event.server.id] ||= {}
      return event.respond "`#{trigger}` does not exist. Perhaps you meant to add one instead?" if @@commands[event.server.id][trigger].nil?
      @@commands[event.server.id][trigger] = output
      save
      event.respond "`#{trigger}` has been updated."
    end

    # Lists all custom commands currently available on the server.
    Manager.bot.command(:listcom) do |event|
      @@commands[event.server.id] ||= {}
      output = "The currently registered custom commands are:\n```\n"
      @@commands[event.server.id].keys.sort.each do |key|
        output += "!#{key}\n"
      end
      output += "```"
    end
  end

  # Adds the commands that were loaded from the custom commands YAML file.
  def add_custom_commands
    @@commands.keys.each do |server|
      @@commands[server].keys.each do |trigger|
        Manager.bot.command(trigger.to_sym) do |event|
          @@commands[event.server.id] ||= {}
          return nil if @@commands[event.server.id][trigger].nil?
          event.respond @@commands[event.server.id][trigger]
        end
      end
    end
  end

  private

  # Adds a role temporarily.
  # @param event [CommandEvent] The event given by the hook.
  # @param args [Array] All the text passed along with the command.
  # @param role_name [String] The name of the role we'll be adding to the user.
  # @param action [String] The word to use for actions.
  # @param action_past [String] The past tense of the word given in action.
  def temp_add_role(event, args, role_name, action, action_past)
    user = event.message.mentions.first
    return event.respond "No user was mentioned in the message." if user.nil?
    member = event.server.member(user.id)
    args.shift(1)
    args -= ["for"]

    if args.first.nil?
      return event.respond "You must provide a time to #{action} for (eg. 1s = 1 second, 1m = 1 minute, 1h = 1 hour)."
    elsif args[1].nil?
      args.push "No reason specified"
    end

    role_obj = event.server.roles.find { |x| x.name == role_name }
    if role_obj.nil?
      event.respond "You must have a role named `#{role_name}` to be able to #{action} users."
    else
      seconds = Utilities::Time.to_seconds(args.first)
      member.add_role(role_obj)
      event.respond "#{user.mention} has been #{action_past} for #{Utilities::Time.humanize(seconds)}."

      time = Time.new + seconds
      while Time.new < time do
        sleep(1)
      end

      member.remove_role(role_obj)
    end
  end

  # Removes a role from a user.
  # @param event [CommandEvent] The event given by the hook.
  # @param name [String] The name of the role to remove.
  # @param action [String] The word to use for the action.
  def remove_role(event, name, action)
    user = event.message.mentions.first
    return event.respond "No user was mentioned in the message." if user.nil?
    member = event.server.member(user.id)
    mute_role = event.server.roles.find { |x| x.name == name }
    member.remove_role(mute_role)
    event.respond "#{user.mention} has been #{action}."
  end
end
