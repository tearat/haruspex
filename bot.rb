require 'telegram/bot'
require 'dotenv/load'

Dotenv.load

TOKEN = ENV['TELEGRAM_BOT_TOKEN']

puts "Bot is running..."

file = File.open("text.txt")
text = file.read
fortunes = text.split "."

loop do
    begin
        Telegram::Bot::Client.run(TOKEN) do |bot|
            puts "Bot activated"
            bot.listen do |request|
                Thread.start(request) do |request|
                    begin
                        case request.text
                        when '/start'
                            puts "Client (#{request.chat.id}): /start"
                            bot.api.send_message(chat_id: request.chat.id, text: "Привет, #{request.from.first_name}! Ты можешь узнать предсказание при помощи команды /oracle")
                        when '/oracle'
                            fortunes.shuffle!
                            fortune = fortunes[0]
                            bot.api.send_message(chat_id: request.chat.id, text: "Твоё будущее: #{fortunes[0]}")
                        when '/stop'
                            puts "Client (#{request.chat.id}): /stop"
                            bot.api.send_message(chat_id: request.chat.id, text: "Пока. Приходи ещё!")
                        end
                    rescue
                        puts "The shit down cause while message parsing"
                    end
                end
            end
        end
    rescue
        puts "The shit down cause a api error"
    end
end
