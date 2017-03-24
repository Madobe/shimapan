require 'yaml'
require 'active_support/core_ext/object/try'

class LogsManager
  # Logs the various happenings on the server to the #server-log channel.

  # Adds a timestamp to the start of the string.
  def timestamp(string)
    "`[%s]` %s" % [Time.now.utc.strftime("%H:%M:%S"), string]
  end

  # Resolves the server ID from the Event object.
  # @param event [Event] The Event object subclass instance.
  def get_server(event)
    if event.try(:server).nil? then event.channel.server else event.server end
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
      @@log = {}
      @@userlist = {}
      Manager.bot.servers.each do |server|
        @@log[server.first] = []
        @@userlist[server.first] = {}
        Manager.bot.server(server.first).members.each do |member|
          @@userlist[server.first][member.id] = {
            :name  => member.display_name,
            :roles => member.roles.map { |x| x.name }
          }
        end
      end
    end

    # Writes a message to the log when a user joins the server.
    Manager.bot.member_join do |event|
      write_message(event, timestamp(":inbox_tray: **%s** (ID:%d) joined the server." % [event.member.username, event.member.id]))
      @@userlist[event.server.id][event.member.id] = []
    end

    # Writes a message to the log when a user leaves or is kicked from the server.
    Manager.bot.member_leave do |event|
      write_message(event, timestamp(":outbox_tray: **%s** (ID:%d) left or was kicked from the server." % [event.member.username, event.member.id]))
    end

    # Writes a message to the log when a user's nickname or roles are changed.
    Manager.bot.member_update do |event|
      cached = @@userlist[event.server.id][event.user.id]
      roles = event.roles.map { |x| x.name }
      diff = cached[:roles] - roles | roles - cached[:roles]
      if diff.empty?
        write_message(event, timestamp(":id: **%s** (ID:%d) changed names to **%s**." % [@@userlist[event.server.id][event.user.id][:name], event.user.id, event.user.display_name]))
        @@userlist[event.server.id][event.user.id][:name] = event.user.display_name
      elsif cached[:name] != event.user.display_name
        @@userlist[event.server.id][event.user.id][:roles] = roles
        write_message(event, timestamp(":name_badge: **%s** (ID:%d) had the **%s** role %s." % [event.user.username, event.user.id, diff.first, cached.size > roles.size ? "removed" : "added"]))
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
      @@log[event.server.id].shift(1) if @@log[event.server.id].size > 100
    end

    # Writes a message to the log when a user deletes a message.
    Manager.bot.message_delete do |event|
      message = get_cached(event, event.id)
      attachments = if message[:attachments].nil? then "" else "\n%s" % message[:attachments] end
      write_message(event, timestamp(":x: **%s**'s message was deleted from %s:\n%s%s" % [message[:author].username, message[:channel].mention, message[:content], attachments]))
      @@log[event.channel.server.id].delete(event.id)
    end

    # Writes a message to the log when a user edits a message.
    Manager.bot.message_edit do |event|
      cached = get_cached(event, event.message.id)
      write_message(event, timestamp(":pencil: **%s**'s message in %s was edited:\n**From:** %s\n**To:** %s" % [event.author.username, event.channel.mention, cached[:content], event.content]))
      cached[:content] = event.content
    end

    # Writes a message to the log when a user is banned.
    Manager.bot.user_ban do |event|
      write_message(event, timestamp(":hammer: **%s** (ID:%d) was banned from the server." % [event.user.username, event.user.id]))
    end

    # Writes a message to the log when a user is unbanned.
    Manager.bot.user_unban do |event|
      write_message(event, timestamp(":warning: **%s** (ID:%d) was unbanned from the server." % [event.user.username, event.user.id]))
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
