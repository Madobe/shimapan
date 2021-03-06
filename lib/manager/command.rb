# frozen_string_literal: true

require 'discordrb'
require 'i18n'
require 'active_record'
require 'workers'
require_relative 'base'
require_relative '../model/custom_command'
require_relative '../model/setting'
require_relative '../model/feed'
require_relative '../model/moderator'
require_relative '../model/past_username'
require_relative '../model/past_nickname'

module Manager
  # Houses all the commands that the bot exposes. Also has all the custom commands and the internal
  # moderator list checking.
  class Commands < Base
    def initialize
      # These options are shared between !set and !unset
      @set_options = %w( mute_role punish_role modlog_channel serverlog_channel absence_channel )
      add_base_commands
      @base_commands = @@bot.commands.keys # Commands that are present on the bot by default; prevent overwrites with custom commands
      add_custom_commands
    end

    # Add every command that's not a custom command.
    def add_base_commands
      # --- Regular Commands ---

      # Provides a link to the wiki documentation.
      @@bot.command(:help) do |event|
        event.respond "Documentation: https://github.com/Madobe/shimapan/wiki"
      end

      # Return the link used to invite the bot to servers.
      @@bot.command(:invite) do |event|
        perms = Discordrb::Permissions.new
        perms.can_kick_members = true
        perms.can_ban_members = true
        perms.can_manage_roles = true
        perms.can_read_messages = true
        perms.can_send_messages = true
        perms.can_manage_messages = true
        url = "<#{@@bot.invite_url}&permissions=#{perms.bits}>"
        event.respond url
      end

      # Returns the previous names of the person whose name is given.
      # @param name [Array<String>] The user's name to search up.
      @@bot.command(:names) do |event, *name|
        member = find_one_member(event, name.join(' '))
        member ||= event.author
        event.respond I18n.t("commands.names", {
          past_usernames: PastUsername.where(user_id: member.id).order('created_at DESC').limit(20).map(&:username).join(", "),
          past_nicknames: PastNickname.where(user_id: member.id).order('created_at DESC').limit(20).map(&:nickname).join(", ")
        })
      end

      # Returns information about the user specified.
      # @param name [Array<String>] The user's name to search up.
      @@bot.command(:userinfo) do |event, *name|
        member = find_one_member(event, name.join(' ')) || event.author
        member = member.on(event.server.id) if member.respond_to?(:on)
        record = Member.where(server_id: event.server.id, user_id: member.id).first

        before = Member.where(server_id: event.server.id).where(["id < ?", record.id]).order("id DESC").limit(3)
        after = Member.where(server_id: event.server.id).where(["id > ?", record.id]).order("id").limit(3).reload
        join_order = before.map { |record| @@bot.user(record.user_id).username }
        join_order << "**#{member.username}**"
        join_order.concat(after.map { |record| @@bot.user(record.user_id).username })

        event.respond I18n.t("commands.userinfo", {
          username:      member.username,
          discriminator: member.discriminator,
          user_id:       member.id,
          nickname:      member.display_name,
          roles:         member.roles.map(&:name).join(", "),
          creation_date: I18n.l(member.creation_time.utc, format: :long),
          join_date:     I18n.l(record.created_at.utc, format: :long),
          join_order:    join_order.join(" > "),
          avatar_url:    member.avatar_url
        })
      end

      @@bot.command(:serverinfo) do |event|
        event.respond I18n.t("commands.serverinfo", {
          server_name:        event.server.name,
          server_id:          event.server.id,
          user_distinct:      event.server.owner.distinct,
          region:             event.server.region,
          online_count:       event.server.online_members.count,
          member_count:       event.server.member_count,
          channel_count:      event.server.channels.count,
          verification_level: event.server.verification_level.to_s.capitalize,
          icon_url:           event.server.icon_url
        })
      end

      # Adds an entry to the absence-log channel for the invoker.
      @@bot.command(:applyforabsence) do |event, *args|
        setting = Setting.where(server_id: event.server.id, option: 'absence_channel').first
        next event.respond I18n.t("commands.applyforabsence.missing_channel") if setting.nil?
        channel = event.server.text_channels.find { |x| x.id == setting.value.to_i }
        next event.respond I18n.t("commands.applyforabsence.channel_gone") if channel.nil?
        reason = if args.size == 0 then I18n.t("commands.common.no_reason") else args.join(' ') end
        channel.send_embed do |embed|
          embed.color       = "#ffff00"
          embed.title       = "Absence Application"
          embed.description = I18n.t("commands.applyforabsence.template", {
            time: I18n.l(Time.new.utc, format: :long),
            applicant: event.author.mention,
            reason: reason
          })
        end
        event.respond I18n.t("commands.applyforabsence.processed")
      end

      # --- Administrator Commands ---

      # Removes the last X messages in a channel. Too abusable so it's an admin command.
      # @param amount [Integer] The amount of messages to remove. Must be between 2 and 100.
      @@bot.command(:prune, required_permissions: [:administrator], usage: '!prune <amount>', min_args: 1) do |event, amount|
        amount = amount.to_i.clamp(2, 100)
        event.channel.prune(amount)
      end

      # Sets the options on the bot.
      # @param option [String] The bot option that's being set.
      # @param value [String,Integer] This will either be a mention or an ID.
      @@bot.command(:set, required_permissions: [:administrator], usage: '!set <option> <value>', min_args: 1) do |event, option, value|
        if option == 'list'
          row_separator = "+#{"-" * 27}+#{"-" * 27}+"
          output = %w( ``` )
          output << row_separator
          output << "| %-25s | %-25s |" % %w( Option Value )
          output << row_separator
          output.concat Setting.where(server_id: event.server.id).map { |setting|
            "| %-25{option} | %-25{value} |" % {
              option: setting.option,
              value:  setting.value
            }
          }
          output << row_separator << "```"
          next event.respond output.join("\n")
        end

        next event.respond I18n.t("commands.set.invalid_option") unless @set_options.include? option

        if value.nil? || value.empty?
          setting = Setting.where(server_id: event.server.id, option: option).first
          setting.destroy unless setting.nil?
          next event.respond I18n.t("commands.set.deleted", option: option)
        end

        setting = Setting.where(server_id: event.server.id, option: option).first
        setting = Setting.new(server_id: event.server.id) if setting.nil?
        setting.option = option
        number_value = value.gsub(/\D/, '')
        object = case option
          when *%w( mute_role punish_role )
            if number_value.empty?
              event.server.roles.find { |role| role.name == value }
            else # This is to check the role actually exists on the server.
              event.server.roles.find { |role| role.id == number_value.to_i }
            end
          when *%w( modlog_channel serverlog_channel absence_channel )
            if number_value.empty?
              event.server.channels.find { |channel| channel.name == value }
            else # This is to check the channel actually exists on the server.
              event.server.channels.find { |channel| channel.id == number_value.to_i }
            end
          end
        if object.respond_to? :id
          setting.value = object.id
          if setting.save
            setting.reload # Force the ActiveRecord object to not use a cached result
            event.respond I18n.t("commands.set.saved", option: option, value: setting.value)
          else
            debug I18n.t("commands.set.debug", server_id: setting.server_id, option: setting.option, value: setting.value)
            event.respond I18n.t("commands.set.failed")
          end
        else
          event.respond I18n.t("commands.set.missing_resource")
        end
      end

      # Unsets a variable for the server.
      # @param option [String] The option to unset.
      @@bot.command(:unset, required_permissions: [:administrator], usage: '!unset <option>', min_args: 1) do |event, option|
        next event.respond I18n.t("commands.set.invalid_option") unless @set_options.include? option
        Setting.where(server_id: event.server.id, option: option).delete_all
        event.respond I18n.t("commands.unset", {
          option: option
        })
      end

      # Adds/removes options for the feed (feed is started via !set).
      # @param log [String] The type of log we're adding/removing options for.
      # @param option [Array] The options. Each will be either solo (like -n) to ignore all
      # display_name changes or will have an ID after them to deny a specific one. Format will always
      # be [+/-][modifier][ID] (eg. -n23940283492430).
      #   +/- n (nick)       display_name changes
      #   +/- e (edit)       message edits
      #   +/- d (delete)     message deletes
      #   +/- v (voice)      user voice channel changes
      #   +/- m (mute)       user mutes, only via this bot (also includes unmutes)
      #   +/- p (punish)     user punishing, only via this bot (also includes unpunishing)
      #   +/- b (ban)        user bans (also includes unbans)
      # These are all actually saved to the same table so the log specification is only for
      # filtering out attempts to modify the feed that are done wrong.
      @@bot.command(:feed, required_permissions: [:administrator], usage: '!feed <log> <option> or !feed <flush/list> <log>', min_args: 1) do |event, log, *options|
        case log
        when 'modlog'
          add_feed_options(event, options, Feed.modlog_modifiers)
        when 'serverlog'
          add_feed_options(event, options, Feed.serverlog_modifiers)
        when 'flush', 'list'
          log_type = options.join('')
          feeds =
            if %w( modlog serverlog ).include? log_type
              modifiers = {
                'modlog'    => Feed.short_modlog_modifiers,
                'serverlog' => Feed.short_serverlog_modifiers
              }
              Feed.where(server_id: event.server.id).where("modifier in (?)", modifiers[log_type])
            else
              Feed.where(server_id: event.server.id)
            end
          if log == 'flush'
            feeds.destroy_all
            event.respond I18n.t("commands.feed.flush")
          else
            event.respond feeds.sort_by(&:modifier).map { |feed|
              "%{allow}%{modifier} for %{target}" % {
                allow:    feed.allow ? "+" : "-",
                modifier: Feed.descriptions[feed.modifier],
                target:   feed.target == 0 ? "all" : "ID:#{feed.target}"
              }
            }.join("\n").prepend("```diff\n").concat("\n```")
          end
        else
          event.respond I18n.t("commands.feed.invalid_log")
        end
      end

      # Adds, removes or lists the moderators for this server.
      # @param action [String] The type of action to perform.
      # @option name [Array<String>] The name of the member to perform the action on.
      @@bot.command(:mod, required_permissions: [:administrator], usage: '!mod <add/remove> <name/mention> or !mod list', min_args: 1) do |event, type, *name|
        server = resolve_server(event)
        name = name.join(' ')

        case type
        when 'add'
          member = find_one_member(event, name)

          mod = Moderator.new
          mod.server_id = server.id
          mod.user_id   = member.id

          if mod.save
            event.respond I18n.t("commands.mod.added", {
              username: member.username,
              user_id:  member.id
            })
          else
            debug I18n.t("commands.mod.failed_debug", errors: mod.errors.full_messages.join(", "))
            next event.respond I18n.t("commands.mod.failed")
          end
        when 'remove'
          member = find_one_member(event, name)
          Moderator.where(server_id: server.id, user_id: member.id).destroy_all
          event.respond I18n.t("commands.mod.removed", {
            username: member.username,
            user_id:  member.id
          })
        when 'list'
          output = %w( ```haskell )
          Moderator.where(server_id: server.id).each do |mod|
            member = server.member(mod.user_id)
            output << member.distinct
          end
          output << " " if output.size == 1 # Prevent "haskell" from showing up if there are no mods
          output << "```"
          event.respond output.join("\n")
        else
          event.respond I18n.t("commands.mod.invalid_type")
        end
      end

      # --- Moderator Commands ---

      # Finds the given role on the server and returns its ID.
      # @param role [String] The name of the role to find.
      @@bot.command(:role, usage: '!role <role>', min_args: 1) do |event, *role|
        next unless is_moderator?(event)
        role = event.server.roles.find { |x| x.name == role.join(' ') }
        next event.respond I18n.t("commands.role.missing") if role.nil?
        event.respond role.id
      end

      # Finds the given user on the server and returns its ID.
      # @param name [String] The name of the user to find.
      @@bot.command(:user, usage: '!user <user>') do |event, name|
        next unless is_moderator?(event)
        member = find_one_member(event, name)
        next event.respond I18n.t("commands.common.no_user_matched") if member.nil?
        event.respond member.id
      end

      # Mutes the mentioned user for the specified amount of time.
      # @param user [String] Must be a mention or ID.
      # @param time [String] Parsed as seconds unless there's a time unit behind it.
      @@bot.command(:mute, usage: '!mute <user> for <time> for <reason>', min_args: 1) do |event, *args|
        next unless is_moderator?(event)
        temp_add_role(:mute, event, args)
      end

      # Unmutes the mentioned user.
      # @param user [String] The mention or name of the user.
      @@bot.command(:unmute, usage: '!unmute <user>', min_args: 1) do |event, *args|
        next unless is_moderator?(event)
        remove_role(:mute, event, args)
      end

      # Punishes the mentioned user.
      # @param user [User] A user mention. Must be a mention or it won't work.
      # @param time [String] Parsed as seconds unless there's a time unit behind it.
      @@bot.command(:punish, usage: '!punish <user> for <time> for <reason>', min_args: 1) do |event, *args|
        next unless is_moderator?(event)
        temp_add_role(:punish, event, args)
      end

      # Unpunishes the mentioned user.
      # @param user [User] A user mention. Must be a mention or it won't work.
      @@bot.command(:unpunish, usage: '!unpunish <user>', min_args: 1) do |event, *args|
        next unless is_moderator?(event)
        remove_role(:punish, event, args)
      end

      # Kicks the mentioned user out of the server.
      # @param user [String] The mention or name of the user.
      @@bot.command(:kick, usage: '!kick <user>', min_args: 1) do |event, user|
        next unless is_moderator?(event)
        user = find_one_member(event, user, true)
        next event.respond I18n.t("commands.common.missing_user") if user.nil?
        event.server.kick(user)
        event.respond I18n.t("commands.kick.completed", user: user.mention)

        write_modlog(event, 'k', "logs.kick", {
          actor:     event.author.username,
          actor_id:  event.author.id,
          target:    user.username,
          target_id: user.id
        })
      end

      # Bans the mentioned user from the server.
      # @param user [String] The mention or name of the user.
      @@bot.command(:ban, usage: '!ban <user>', min_args: 1) do |event, user, days|
        next unless is_moderator?(event)
        user = find_one_member(event, user, true)
        next event.respond I18n.t("commands.common.missing_user") if user.nil?
        event.server.ban(user, days.to_i)
        event.respond I18n.t("commands.ban.completed", user: user.mention)

        write_modlog(event, 'b', "logs.ban", {
          actor:     event.author.username,
          actor_id:  event.author.id,
          target:    user.username,
          target_id: user.id
        })
      end

      # Unbans the mentioned user from the server.
      # @param user [String] Must be an ID.
      @@bot.command(:unban, usage: '!unban <user>', min_args: 1) do |event, user|
        next unless is_moderator?(event)
        # Fool the find_one_member command into using the ban list by creating the Event object.
        fake_event = Struct.new(:server).new
        fake_event.server = Struct.new(:members).new(event.server.bans)
        user = find_one_member(fake_event, user, true)
        event.server.unban(user)
        event.respond I18n.t("commands.unban.completed", user: "<@!#{user.respond_to?(:id) ? user.id : user}>")

        write_modlog(event, 'b', "logs.unban", {
          actor:     event.author.username,
          actor_id:  event.author.id,
          target_id: user.respond_to?(:id) ? user.id : user
        })
      end

      # Does CRUD for custom commands.
      # @param action [String] The operation to perform.
      # @param trigger [String] The trigger that will be used as the command.
      # @param output [Array<String>] The string that will serve as the output.
      @@bot.command(:com, usage: '!com <add/remove/edit/list> <trigger> <output>', min_args: 1) do |event, action, trigger, *output|
        case action
        when 'add'
          next unless is_moderator?(event)
          check = CustomCommand.where(server_id: event.server.id, trigger: trigger).first
          next event.respond I18n.t("commands.com.already_exists", trigger: trigger) unless check.nil?
          next event.respond I18n.t("commands.com.cannot_shadow", trigger: trigger) if @base_commands.include?(trigger.to_sym)

          command = CustomCommand.new(server_id: event.server.id, trigger: trigger, output: output.join(' '))
          next event.respond I18n.t("commands.com.save_failed") unless command.save

          add_custom_command(command)

          event.respond I18n.t("commands.com.added", trigger: trigger)
        when 'remove'
          next unless is_moderator?(event)
          command = CustomCommand.where(server_id: event.server.id, trigger: trigger)
          command.first.delete
          event.respond I18n.t("commands.com.removed", trigger: trigger)
        when 'edit'
          next unless is_moderator?(event)
          command = CustomCommand.where(server_id: event.server.id, trigger: trigger).first
          next event.respond I18n.t("commands.com.missing_trigger", trigger: trigger) if command.nil?
          command.update(output: output.join(' '))
          event.respond I18n.t("commands.com.edited", trigger: trigger)
        when 'list'
          I18n.t("commands.com.list", {
            command_list: CustomCommand.where(server_id: event.server.id).map(&:trigger).sort.map { |trigger| "!#{trigger}" }.join("\n")
          })
        else
          event.respond I18n.t("commands.com.invalid_action")
        end
      end
    end

    # Adds a single custom command to the bot.
    # @param command [CustomCommand] The command we're adding to the bot.
    def add_custom_command(command)
      @@bot.command(command.trigger.to_sym) do |event|
        command.reload
        next nil if command.server_id != event.server.id
        event.respond command.output
      end
    end

    # Adds all the custom commands in the database to the bot.
    def add_custom_commands
      CustomCommand.all.each do |command|
        add_custom_command(command)
      end
    end

    # Check whether the user has moderator permissions on the current server.
    # @param event [CommandEvent] The event object.
    def is_moderator?(event)
      return true if event.author.owner?
      record = Moderator.where(server_id: event.server.id, user_id: event.author.id).first
      return false if record.nil?
      true
    end

    # The functionality that actually processes the feed.
    # @param event [Event] The Event object.
    # @param options [Array<String>] The options that were passed to the command.
    # @param modifiers [Array<String>] The modifiers that are allowed for this log type.
    def add_feed_options(event, options, modifiers)
      regex = /([\+\-]{1})([a-zA-Z]+)(\d*)/
      output = []
      options.each do |option|
        if modifiers.include?(modifier = option.gsub(/[^a-zA-Z]/, ''))
          allow, modifier, target = regex.match(option).to_a[1..-1]

          if allow.nil?
            output << "#{option}: #{I18n.t("commands.feed.missing_allow")}"
            next
          end

          allow = { "+" => true, "-" => false }[allow]
          target = 0 if target.empty?

          feed = Feed.where(server_id: event.server.id, allow: !allow, modifier: modifier[0], target: target)
          if feed.empty?
            feed = Feed.new(server_id: event.server.id, allow: allow, modifier: modifier[0], target: target)
            if feed.save
              output << "#{option}: #{I18n.t("commands.feed.saved")}"
            else
              p feed.errors
              output << "#{option}: #{I18n.t("commands.feed.failed")}"
            end
          else
            if feed.update(allow: allow)
              output << "#{option}: #{I18n.t("commands.feed.updated")}"
            else
              p feed.errors
              output << "#{option}: #{I18n.t("commands.feed.failed")}"
            end
          end
        end
      end
      event.respond output.join("\n")
    end

    # Temporarily adds a role to a user.
    # @param type [Symbol] The type of role being added. Literally just a symbol for highlighting.
    # @param event [Event] The Event object.
    # @param args [Array] The arguments that were sent to the command. Should have a time and
    # possibly a reason.
    def temp_add_role(type, event, args)
      role_id = Setting.where(server_id: event.server.id, option: type.to_s + "_role").first.value.to_i

      return event.respond I18n.t("commands.common.missing_time") if args[1].nil?
      args -= %w( for )
      args.push I18n.t("commands.common.no_reason") if args[2].nil?

      user = find_one_member(event, args[0])
      return event.respond I18n.t("commands.common.missing_user") if user.nil?
      member = event.server.member(user.id)

      role = event.server.roles.find { |role| role.id == role_id }
      return event.respond I18n.t("commands.common.deleted_role") if role.nil?
      
      member.add_role(role)
      seconds = Utilities::Time.to_seconds(args[1])
      ::Workers::Timer.new(seconds) { member.remove_role(role) }
      event.respond I18n.t("commands.#{type}.completed", user: member.display_name, time: Utilities::Time.humanize(seconds))
      
      write_modlog(event, Feed.shorten_modifier(type.to_s), "logs.#{type}", {
        actor:     event.author.username,
        actor_id:  event.author.id,
        target:    user.username,
        target_id: user.id,
        time:      Utilities::Time.humanize(seconds),
        reason:    args[2..-1].join(' ')
      })
    rescue NoMethodError
      nil
    end

    # Removes a role from a user.
    # @param type [Symbol] The type of role being removed.
    # @param event [Event] The Event object.
    # @param args [Array<String>] The arguments that were sent to the command. We only take the
    # first argument because we only accept a name or mention.
    def remove_role(type, event, args)
      user = find_one_member(event, args[0])
      event.respond I18n.t("commands.common.missing_user") if user.nil?
      member = event.server.member(user.id)

      role_id = Setting.where(server_id: event.server.id, option: type.to_s + "_role").first.value
      role = event.server.roles.find { |role| role.id == role_id.to_i }

      member.remove_role(role)
      event.respond I18n.t("commands.un#{type}.completed", user: member.display_name)

      write_modlog(event, Feed.shorten_modifier(type.to_s), "logs.un#{type}", {
        actor:     event.author.username,
        actor_id:  event.author.id,
        target:    user.username,
        target_id: user.id
      })
    end

    # Writes an entry to the moderation log, if the channel is set and writing for this action is
    # allowed.
    # @param event [CommandEvent] The event object.
    # @param modifier [String] The one character modifier for feeds.
    # @param message_path [String] The path for I18n.
    # @param hash [String] The interpolation hash to pass to I18n.
    def write_modlog(event, modifier, message_path, hash)
      modlog_channel = Setting.where(server_id: event.server.id, option: 'modlog_channel').first
      modlog_setting = Feed.where(server_id: event.server.id, modifier: modifier).first
      return unless modlog_channel && ((modlog_setting && modlog_setting.allow) || !modlog_setting)

      modlog_channel = event.server.text_channels.find { |channel| channel.id == modlog_channel.value.to_i }
      modlog_channel.send_message I18n.t(message_path, hash)
    end
  end
end
