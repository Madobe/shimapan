Dir['/models/*.rb'].each { |file| require file }
require_relative 'datatype/query'

class LogsManager
  # Logs the various happenings on the server to the #server-log channel.

  # Adds a timestamp to the start of the string.
  def timestamp(string)
    "`[%s]` %s" % [Time.now.utc.strftime("%H:%M:%S"), string]
  end

  # Resolves the server ID from the Event object.
  # @param event [Event] The Event object subclass instance.
  def get_server(event)
    if event.methods.include? :server then event.server else event.channel.server end
  end

  # Tries to find a cached message based on its ID.
  # @param id [Integer] The ID of the Message.
  def get_cached(event, id)
    @@log[get_server(event).id].find { |x| x.first == id }[1]
  end

  # Attaches all the event listeners to the bot.
  # @param bot [CommandBot] The instance of our bot.
  def initialize
    # Prepares the caches for messages and user info.
    Manager.bot.ready do |event|
      Manager.bot.servers.each do |server|
        Manager.bot.server(server.first).members.each do |member|
          record = Member.new
          record.server_id    = server.first
          record.user_id      = member.id
          record.display_name = member.display_name
          record.avatar       = member.avatar_url
          record.save
        end
      end
    end

    # Writes a message to the log when a user joins the server.
    Manager.bot.member_join do |event|
      write_message(event, timestamp(":inbox_tray: **%{username}** (ID:%{user_id}) joined the server." % {
        username: event.member.username,
        user_id:  event.member.id
      }))

      member = Member.new
      member.server_id    = get_server(event).id
      member.user_id      = event.member.id
      member.display_name = event.member.display_name
      member.avatar       = event.member.avatar_url
      member.save
    end

    # Writes a message to the log when a user leaves or is kicked from the server.
    Manager.bot.member_leave do |event|
      write_message(event, timestamp(":outbox_tray: **%{username}** (ID:%{user_id}) left or was kicked from the server." % {
        username: event.member.username,
        user_id:  event.member.id
      }))

      Member.delete(get_server(event).id, event.member.id)
    end

    # Writes a message to the log when a user's nickname or roles are changed.
    Manager.bot.member_update do |event|
      member = Member.get(
      cached = @@userlist[event.server.id][event.user.id]
      roles = event.roles.map { |x| x.name }
      diff = cached[:roles] - roles | roles - cached[:roles]
      if cached[:name] != event.user.display_name
        write_message(event, timestamp(":id: **%{username}** (ID:%{user_id}) changed names to **%{new_user_id}**." % {
          username:    @@userlist[event.server.id][event.user.id][:name],
          user_id:     event.user.id,
          new_user_id: event.user.display_name
        }))
        @@userlist[event.server.id][event.user.id][:name] = event.user.display_name
      elsif not diff.empty?
        write_message(event, timestamp(":name_badge: **%{username}** (ID:%{user_id}) had the **%{role_name}** role %{add_or_rm}." % {
          username:  event.user.username,
          user_id:   event.user.id,
          role_name: diff.first,
          add_or_rm: cached[:roles].size > roles.size ? "removed" : "added"
        }))
        @@userlist[event.server.id][event.user.id][:roles] = roles
      end
    end

    # Caches a message when it's sent so we can tell what it was when it's deleted.
    Manager.bot.message do |event|
      entry = [
        event.message.id,
        {
          :attachments => event.message.attachments.first.try(:url),
          :channel     => event.message.channel,
          :author      => event.message.author,
          :content     => event.message.content
        }
      ]
      @@log[event.server.id].push(entry)
      @@log[event.server.id].shift if @@log[event.server.id].size > 100
    end

    # Writes a message to the log when a user deletes a message.
    Manager.bot.message_delete do |event|
      message = get_cached(event, event.id)
      attachments = if message[:attachments].nil? then "" else message[:attachments] end
      write_message(event, timestamp(":x: **%{username}**'s message was deleted from %{channel}:\n%{content}%{attachment}" % {
        username:   message[:author].username,
        channel:    message[:channel].mention,
        content:    message[:content],
        attachment: "\n#{attachments}"
      }))
      @@log[event.channel.server.id].delete(event.id)
    end

    # Writes a message to the log when a user edits a message.
    Manager.bot.message_edit do |event|
      cached = get_cached(event, event.message.id)
      write_message(event, timestamp(":pencil: **%{username}**'s message in %{channel} was edited:\n**From:** %{from}\n**To:** %{to}" % {
        username: event.author.username,
        channel:  event.channel.mention,
        from:     cached[:content],
        to:       event.content
      }))
      cached[:content] = event.content
    end

    # Writes a message to the log when a user is banned.
    Manager.bot.user_ban do |event|
      write_message(event, timestamp(":hammer: **%{username}** (ID:%{user_id}) was banned from the server." % {
        username: event.user.username,
        user_id:  event.user.id
      }))
    end

    # Writes a message to the log when a user is unbanned.
    Manager.bot.user_unban do |event|
      write_message(event, timestamp(":warning: **%{username}** (ID:%{user_id}) was unbanned from the server." % {
        username: event.user.username,
        user_id:  event.user.id
      }))
    end
  end

  # Writes a message to the #server-log channel.
  # @param event [Event] Some random kind of event. Not every event comes with #server.
  # @param message [String] The message to put in #server-log. Put into the log as-is.
  def write_message(event, message)
    server = get_server(event)
    channel = server.text_channels.find { |x| x.name == "server-log" }
    channel.send_message message
  end
end
