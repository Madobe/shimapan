require_relative 'base'
require_relative '../module/utilities'
require_relative '../model/message'
require_relative '../model/member'
require_relative '../model/role'
require_relative '../model/setting'
require_relative '../model/feed'

module Manager
  class Logs < Base
    def initialize
      @@bot.servers.each do |server_id, server|
        server.members.each do |member|
          Member.new(
            server_id:    server_id,
            user_id:      member.id,
            display_name: member.display_name,
            avatar:       member.avatar_url
          ).save

          member.roles.each do |role|
            Role.new(
              server_id: server_id,
              user_id:   member.id,
              role_id:   role.id
            ).save
          end
        end
      end

      # Event that runs when somebody joins the server.
      @@bot.member_join do |event|
        write_message(event, I18n.t("logs.member_join.message", {
          username: event.member.username,
          user_id:  event.member.id
        }))
        
        member = Member.new
        member.server_id    = event.server.id
        member.user_id      = event.member.id
        member.display_name = event.member.display_name
        member.avatar       = event.member.avatar_url
        unless member.save
          debug I18n.t("logs.member_join.debug", {
            server_id:    member.server_id,
            user_id:      member.user_id,
            display_name: member.display_name,
            avatar:       member.avatar
          })
        end
      end

      # Event that runs when somebody leaves the server.
      @@bot.member_leave do |event|
        write_message(event, I18n.t("logs.member_leave.message", {
          username: event.member.username,
          user_id:  event.member.id
        }))
        member = Member.where(server_id: event.server.id, user_id: event.user.id).first
        begin
          member.destroy
        rescue NoMethodError
          debug I18n.t("logs.member_leave.debug", {
            server_id: event.server.id,
            user_id:   event.user.id
          })
        end
      end

      # Event that runs when somebody changes their display name.
      @@bot.member_update do |event|
        begin
          server = resolve_server(event)
          member = Member.where(server_id: server.id, user_id: event.user.id).first
          unless member.update(display_name: event.user.display_name)
            debug I18n.t("logs.member_update.nick.debug", {
              user_id: event.user.id
            })
          end

          next unless Feed.check_perms(server, 'nick', event.user.id)

          if member.display_name != event.user.display_name
            write_message(event, I18n.t("logs.member_update.nick.message", {
              display_name:     member.display_name,
              user_id:          event.user.id,
              new_display_name: event.user.display_name
            }))
          end
        rescue NoMethodError
          debug I18n.t("logs.member_update.nick.no_method_error", {
            user_id: event.user.id
          })
        end
      end

      # Event that runs when somebody's roles get changed.
      @@bot.member_update do |event|
        server = resolve_server(event)
        member = Member.where(server_id: server.id, user_id: event.user.id).first
        old_roles = Role.where(server_id: server.id, user_id: event.user.id).map(&:role_id)
        new_roles = event.roles.map(&:id)
        diff = new_roles - old_roles | old_roles - new_roles
        
        if diff.empty?
          next
        elsif new_roles.size > old_roles.size
          diff.each do |role_id|
            role = Role.new(server_id: server.id, user_id: event.user.id, role_id: role_id).save
          end
        else
          diff.each do |role_id|
            Role.where(server_id: server.id, user_id: event.user.id, role_id: role_id).delete_all
          end
        end

        next unless Feed.check_perms(server, 'role', event.user.id)

        if !diff.empty?
          if new_roles.size > old_roles.size
            write_message(event, I18n.t("logs.member_update.role.added", {
              username: event.user.name,
              user_id:  event.user.id,
              roles:    diff.map { |role_id| server.role(role_id).name }.join(', ')
            }))
          else
            write_message(event, I18n.t("logs.member_update.role.removed", {
              username: event.user.name,
              user_id:  event.user.id,
              roles:    diff.map { |role_id| server.role(role_id).name }.join(', ')
            }))
          end
        end
      end

      # Event that runs whenever somebody sends a message. This is ALWAYS on. It just won't report
      # the messages to the logs.
      @@bot.message do |event|
        message = Message.new(
          server_id:   resolve_server(event).id,
          channel_id:  event.channel.id,
          user_id:     event.author.id,
          message_id:  event.message.id,
          username:    event.author.username,
          content:     event.message.content,
          attachments: event.message.attachments.map(&:url).join("\n")
        )
        unless message.save
          debug I18n.t("logs.message.debug", {
            message_id: event.message.id
          })
        end
      end

      # Event that runs whenever somebody edits a message.
      @@bot.message_edit do |event|
        server = resolve_server(event)
        message = Message.where(server_id: server.id, message_id: event.message.id).first
        next if message.nil?
        old_message = message.dup
        message.update(
          content: event.message.content,
          attachments: event.message.attachments.map(&:url).join("\n")
        )

        next unless Feed.check_perms(server, 'edit', event.author.id) && Feed.check_perms(server, 'channel', event.channel.id)

        write_message(event, I18n.t("logs.message_edit.message", {
          username: event.author.username,
          channel:  event.channel.mention,
          from:     old_message.to_printable,
          to:       Message.new(content: event.message.content, attachments: event.message.attachments.map(&:url).join("\n")).to_printable
        }))
      end

      # Event that runs whenever somebody deletes a message.
      @@bot.message_delete do |event|
        server = resolve_server(event)
        message = Message.where(server_id: server.id, message_id: event.id).first
        next if message.nil?
        message.delete

        next unless Feed.check_perms(server, 'delete', message.user_id) 
        write_message(event, I18n.t("logs.message_delete.message", {
          username: message.username,
          channel:  event.channel.mention,
          message:  message.to_printable
        }))
      end

      # Event that runs whenever a user is banned from a server.
      @@bot.user_ban do |event|
        next unless Feed.check_perms(event.server, 'ban', event.user.id)
        write_message(event, I18n.t("logs.user_ban.message", {
          username: event.user.username,
          user_id:  event.user.id
        }))
        # member_leave handles the deletion of records
      end

      # Event that runs whenever a user is unbanned from a server.
      @@bot.user_unban do |event|
        next unless Feed.check_perms(event.server, 'ban', event.user.id)
        write_message(event, I18n.t("logs.user_unban.message", {
          username: event.user.username,
          user_id:  event.user.id
        }))
      end

      # Event that runs whenever a user swaps voice channels.
      @@bot.voice_state_update do |event|
        next unless event.old_channel || event.channel && Feed.check_perms(event.server, 'voice', event.user.id)
        if event.old_channel && event.channel
          write_message(event, I18n.t("logs.voice_state_update.change", {
            username: event.user.username,
            user_id:  event.user.id,
            channel:  event.channel.name
          }))
        elsif event.old_channel
          write_message(event, I18n.t("logs.voice_state_update.leave", {
            username: event.user.username,
            user_id:  event.user.id,
            channel:  event.old_channel.name
          }))
        else
          write_message(event, I18n.t("logs.voice_state_update.join", {
            username: event.user.username,
            user_id:  event.user.id,
            channel:  event.channel.name
          }))
        end
      end
    end

    # Write a message to the relevant log channel. Does nothing if the channel isn't set or if the
    # channel is missing.
    # @param event [Event] Any kind of Event object.
    # @param message [String] The text to print to the channel.
    # @option log [String] The log to print to.
    def write_message(event, message, log = "serverlog")
      return debug("Invalid log specified for Manager::Logs#write_message.") unless %w( serverlog modlog ).include? log
      server = resolve_server(event)
      setting = Setting.where(server_id: server.id, option: "#{log}_channel").first
      return if setting.nil?
      channel = server.text_channels.find { |channel| channel.id == setting.value.to_i }
      return setting.delete if channel.nil? # Channel was deleted so we don't need this Setting anymore.
      channel.send_message message.timestamp
    end
  end
end
