require_relative 'base'

module Manager
  class Music < Base
    def initialize
      # Blanket command for all the music functionality (namespacing).
      @@bot.command(:music) do |event, subcommand, link|
        case subcommand
        # Connect the bot to the user's voice channel.
        when *%w( bind start )
          if event.voice
            event.respond I18n.t("music.bind.already_connected")
          elsif !event.author.voice_channel
            event.respond I18n.t("music.bind.no_channel")
          else
            @@bot.voice_connect(event.author.voice_channel)
            event.respond I18n.t("music.bind.connected", {
              channel:  event.author.voice_channel.name,
              username: event.author.username
            })
          end
        # Disconnect the bot from whatever channel it's currently on. Can't disconnect if a song is
          # playing.
        when *%w( unbind stop )
          next event.respond I18n.t("music.not_connected") unless event.voice
          next event.respond I18n.t("music.cant_halt_playback") unless !@playing
          event.voice.destroy
          nil
        when *%w( play )
          next event.respond I18n.t("music.not_connected") unless event.voice
        else
          event.respond I18n.t("music.help")
        end
      end
    end
  end
end
