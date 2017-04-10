require 'i18n'
require_relative 'base'
require_relative '../model/custom_command'
require_relative '../model/setting'
require_relative '../model/feed'

module Manager
  class Commands < Base
    def initialize
      add_base_commands
      add_custom_commands
      @@bot.sync
    end

    def add_base_commands
      @@bot.command(:help) do |event, command|
        if command.nil?
          event.respond I18n.t("commands.help.default")
        else
          event.respond I18n.t("help.#{command}", default: I18n.t("commands.help.no_documentation"))
        end
      end

      # Sets the options on the bot.
      # @param option [String] The bot option that's being set.
      # @param value [String,Integer] This will either be a mention or an ID.
      @@bot.command(:set, required_permissions: [:administrator], usage: '!set <option> <value>', min_args: 2) do |event, option, value|
        options = %w( mute_role punish_role modlog_channel serverlog_channel absence_channel )
        return event.respond I18n.t("commands.set.invalid_option") unless options.include? option

        if value.nil? || value.empty?
          setting = Setting.where(server_id: event.server.id, option: option).first
          setting.destroy
          return event.respond I18n.t("commands.set.deleted")
        end

        setting = Setting.where(server_id: event.server.id, option: option).first
        setting = Setting.new(server_id: event.server.id) if setting.nil?
        setting.option = option
        begin
          setting.value =
            if value.gsub(/\D/, '').empty?
              case option
              when %w( mute_role punish_role )
                event.server.roles.find { |role| role.name == value }.id
              when %w( modlog_channel serverlog_channel absence_channel )
                event.server.channels.find { |channel| channel.name == value }.id
              end
            else
              value.gsub(/\D/, '')
            end
        rescue NoMethodError => e
          self.debug "Role or channel could not be found for !set."
          return event.respond I18n.t("commands.set.missing_resource")
        end
        if setting.save
          setting.reload # Force the ActiveRecord object to not use a cached result
          event.respond I18n.t("commands.set.saved", option: option, value: setting.value)
        else
          debug I18n.t("commands.set.debug", server_id: setting.server_id, option: setting.option, value: setting.value)
          event.respond I18n.t("commands.set.failed")
        end
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
          add_feed_options(event, options, %w( m mute p punish b ban ))
        when 'serverlog'
          add_feed_options(event, options, %w( n nick e edit d delete v voice ))
        when 'flush'
          log_type = options.join('')
          feed =
            if %w( modlog serverlog ).include? log_type
              modifiers = {
                'modlog'    => %w( m p b ),
                'serverlog' => %w( n e d v )
              }
              Feed.where(server_id: event.server.id).where("modifier in (?)", modifiers[log_type])
            else
              Feed.where(server_id: event.server.id)
            end
          feed.destroy_all
          event.respond I18n.t("commands.feed.flush")
        when 'list'
        else
          event.respond I18n.t("commands.feed.invalid_log")
        end
      end

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
              if feed.update_attributes(allow: allow)
                output << "#{option}: #{I18n.t("commands.feed.saved")}"
              else
                p feed.errors
                output << "#{option}: #{I18n.t("commands.feed.failed")}"
              end
            end
          end
        end
        event.respond output.join("\n")
      end

      # Adds an entry to the absence-log channel for the invoker.
      @@bot.command(:applyforabsence) do |event, *args|
        setting = Setting.where(server_id: event.server.id, option: 'absence_channel').first
        return event.respond I18n.t("commands.applyforabsence.missing_channel") if setting.nil?
        channel = event.server.text_channels.find { |x| x.id == setting.value }
        reason = if args.size == 0 then I18n.t("commands.common.no_reason") else args.join(' ') end
        channel.send_message I18n.t("commands.applyforabsence.template", {
          time: Time.new.utc.strftime(I18n.t("commands.applyforabsence.datetime_format")),
          applicant: event.author.mention,
          reason: reason
        })
        event.respond I18n.t("commands.applyforabsence.processed")
      end

      # Finds the given role on the server and returns its ID.
      # @param role [String] The name of the role to find.
      @@bot.command(:role, required_permissions: [:manage_roles], usage: '!role <role>', min_args: 1) do |event, *role|
        role = event.server.roles.find { |x| x.name == role.join(' ') }
        return event.respond I18n.t("commands.role.missing") if role.nil?
        event.respond role.id
      end

      # Mutes the mentioned user for the specified amount of time.
      # @param user [String] Must be a mention or ID.
      # @param time [String] Parsed as seconds unless there's a time unit behind it.
      @@bot.command(:mute, required_permissions: [:manage_roles], usage: '!mute <user> for <time> for <reason>', min_args: 1) do |event, *args|
        temp_add_role(:mute, event, args)
      end

      # Unmutes the mentioned user.
      # @param user [User] A user mention. Must be a mention or it won't work.
      @@bot.command(:unmute, required_permissions: [:manage_roles], usage: '!unmute <user>', min_args: 1) do |event, *args|
        remove_role(:mute, event, args)
      end

      # Punishes the mentioned user.
      # @param user [User] A user mention. Must be a mention or it won't work.
      # @param time [String] Parsed as seconds unless there's a time unit behind it.
      @@bot.command(:punish, required_permissions: [:manage_roles], usage: '!punish <user> for <time>', min_args: 1) do |event, *args|
        temp_add_role(:punish, event, args)
      end

      # Unpunishes the mentioned user.
      # @param user [User] A user mention. Must be a mention or it won't work.
      @@bot.command(:unpunish, required_permissions: [:manage_roles], usage: '!unpunish <user>', min_args: 1) do |event, *args|
        remove_role(:punish, event, args)
      end

      # Kicks the mentioned user out of the server.
      # @param user [String] Must be a mention.
      @@bot.command(:kick, required_permissions: [:kick_members], usage: '!kick <user>', min_args: 1) do |event|
        user = event.message.mentions.first
        return event.respond I18n.t("commands.common.missing_user") if user.nil?
        event.server.kick(user)
        event.respond I18n.t("commands.kick.completed", user: user.mention)
      end

      # Bans the mentioned user from the server.
      # @param user [String] Must be a mention.
      @@bot.command(:ban, required_permissions: [:ban_members], usage: '!ban <user>', min_args: 1) do |event|
        user = event.message.mentions.first
        return event.respond I18n.t("commands.common.missing_user") if user.nil?
        event.server.ban(user)
        event.respond I18n.t("commands.ban.completed", user: user.mention)
      end

      # Unbans the mentioned user from the server.
      # @param user [String] Must be an ID.
      @@bot.command(:unban, required_permissions: [:ban_members], usage: '!unban <user>', min_args: 1) do |event, user|
        event.server.unban(user)
        event.respond I18n.t("commands.unban.completed", user: "<@#{user}>")
      end

      # Adds a custom command for this server.
      # @param trigger [String] The trigger phrase for the custom command.
      # @param output [String] The bot's response to the trigger.
      @@bot.command(:addcom, required_permissions: [:manage_messages], usage: '!addcom <trigger> <output>', min_args: 2) do |event, trigger, output|
        check = CustomCommand.where(server_id: event.server.id, trigger: trigger).first
        return event.respond I18n.t("commands.addcom.already_exists", trigger: trigger) unless check.nil?

        command = CustomCommand.new(server_id: event.server.id, trigger: trigger, output: output)
        return event.respond I18n.t("commands.addcom.save_failed") unless command.save

        @@bot.command(trigger.to_sym) do |event|
          command = CustomCommand.where(server_id: event.server.id).first
          return nil if command.nil?
          event.respond command.output
        end

        event.respond I18n.t("commands.addcom.completed", trigger: trigger)
      end

      # Deletes a custom command for this server.
      # @param trigger [String] The trigger phrase for the custom command.
      @@bot.command(:delcom, required_permissions: [:manage_messages], usage: '!delcom <trigger>', min_args: 1) do |event, trigger|
        command = CustomCommand.where(server_id: event.server.id, trigger: trigger).first
        command.delete
        command.reload # Force the ActiveRecord object to not use a cached result
        event.respond I18n.t("commands.delcom.completed", trigger: trigger)
      end

      # Edits a currently existing custom command for this server.
      # @param trigger [String] The trigger phrase for the custom command.
      # @param output [String] The bot's response to the trigger.
      @@bot.command(:editcom, required_permissions: [:manage_messages], usage: '!editcom <trigger> <output>', min_args: 2) do |event, trigger, output|
        command = CustomCommand.where(server_id: event.server.id, trigger: trigger).first
        return event.respond I18n.t("commands.editcom.missing_trigger", trigger: trigger) if command.nil?
        command.output = output
        command.save
        event.respond I18n.t("commands.editcom.completed", trigger: trigger)
      end

      # Lists all custom commands currently available on the server.
      @@bot.command(:listcom) do |event|
        I18n.t("commands.listcom", {
          command_list: CustomCommand.where(server_id: event.server.id).map(&:trigger).sort.map { |trigger| "!#{trigger}" }.join("\n")
        })
      end
    end

    # Adds all the custom commands in the database to the bot.
    def add_custom_commands
      CustomCommand.all.each do |command|
        @@bot.command(command.trigger.to_sym) do |event|
          return nil if command.server_id != event.server.id
          event.respond command.output
        end
      end
    end

    def temp_add_role(type, event, args)
      role_id = Setting.where(server_id: event.server.id, option: type.to_s + "_role").first.value

      return event.respond I18n.t("commands.common.missing_time") if args.first.nil?
      args = args[1..-1] - %w( for )
      args.push I18n.t("commands.common.no_reason") if args[1].nil?

      user = (event.message.mentions || find_member(event, args[0])).first
      return event.respond I18n.t("commands.common.missing_user") if user.nil?
      member = event.server.member(user.id)

      role = event.server.roles.find { |role| role.id == role_id }
      return event.respond I18n.t("commands.common.deleted_role") if role.nil?
      
      member.add_role(role)
      seconds = Utilities::Time.to_seconds(args.first)
      Timer.new(seconds) { member.remove_role(role) }
    end

    def remove_role(type, event, args)
      user = (event.message.mentions || find_member(event, args[0])).first
      event.respond I18n.t("commands.common.missing_user") if user.nil?
      member = event.server.member(user.id)

      role_id = Setting.where(server_id: event.server.id, option: type.to_s + "_role").first.value
      role = event.server.roles.find { |role| role.id == role_id }

      member.remove_role(role)
      event.respond I18n.t("commands.common.role_removed")
    end
  end
end
