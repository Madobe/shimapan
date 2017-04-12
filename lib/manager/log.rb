require_relative 'base'
require_relative '../module/utilities'
require_relative '../model/member'
require_relative '../model/role'
require_relative '../model/setting'
require_relative '../model/feed'

module Manager
  class Logs < Base
    def initialize
      @@bot.servers.each do |server_id, server|
        server.members.each do |member|
          record = Member.new
          record.server_id    = server_id
          record.user_id      = member.id
          record.display_name = member.display_name
          record.avatar       = member.avatar_url
          record.save

          member.roles.each do |role|
            record = Role.new
            record.server_id = server_id
            record.user_id   = member.id
            record.role_id   = role.id
            record.save
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

          return unless permission_check('nick', server, event.user.id)

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
          return
        elsif new_roles.size > old_roles.size
          diff.each do |role_id|
            role = Role.new(server_id: server.id, user_id: event.user.id, role_id: role_id).save
          end
        else
          diff.each do |role_id|
            Role.where(server_id: server.id, user_id: event.user.id, role_id: role_id).delete_all
          end
        end

        return unless permission_check('role', server, event.user.id)

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
    end

    # Check the feed settings for whether we should be logging this action.
    def permission_check(modifier, server, target)
      settings = Feed.where(server_id: server.id, modifier: Feed.shorten_modifier(modifier))
      return true if settings.empty? # All logging is enabled by default
      blanket_setting = Feed.where(server_id: server.id, modifier: modifier, target: 0).first
      user_specific_setting = Feed.where(server_id: server.id, modifier: modifier, target: target).first
      return blanket_setting.allow if !blanket_setting.nil? && user_specific_setting.empty?
      user_specific_setting.allow
    end

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
