require 'yaml'
require 'discordrb'

connection_config = YAML.load_file('config/connect.yaml')

bot = Discordrb::Bot.new token: connection_config['token'], client_id: connection_config['client_id']

bot.message(with_text: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.run
