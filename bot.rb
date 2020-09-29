require 'telegram/bot'
require 'dotenv/load'

dotenv_url = File.join(File.dirname(__FILE__), "/.env")
Dotenv.load dotenv_url
TOKEN = ENV['TELEGRAM_BOT_TOKEN']

text_url = File.join(File.dirname(__FILE__), "/text.txt")
file = File.open(url)
text = file.read
fortunes = text.split /\n|\./
puts "#{fortunes.length} sentences loaded"

loop do
    begin
        Telegram::Bot::Client.run(TOKEN) do |bot|
            puts "Bot run"
            bot.listen do |request|
                puts "Bot listen"
                Thread.start(request) do |request|
                    puts ""
                    puts "Thread start"

                    kb = [
                      Telegram::Bot::Types::InlineKeyboardButton.new(text: '🧡 Предсказание 🧡', callback_data: 'oracle'),
                    ]
                    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

                    begin
                        if request.class == Telegram::Bot::Types::CallbackQuery
                            case request.data
                            when 'oracle'
                                puts "Client (#{request.from.id}) asks a fortune"
                                fortune = ""
                                while fortune.length < 3 do
                                    fortunes.shuffle!
                                    fortune = fortunes[0].strip
                                end
                                puts "Fortune: #{fortune}"
                                puts ""
                                bot.api.send_message(
                                    chat_id: request.from.id,
                                    parse_mode: 'markdown',
                                    text: "*Твоё будущее:*\n\n#{fortune}...",
                                    reply_markup: markup
                                )
                            end
                        end

                        if request.class == Telegram::Bot::Types::Message
                            case request.text
                            when '/start'
                                puts "Client (#{request.chat.id}): /start"
                                bot.api.send_message(
                                    chat_id: request.chat.id,
                                    text: "Привет, #{request.from.first_name}!\nТы можешь узнать предсказание при помощи кнопки ниже!",
                                    reply_markup: markup
                                )
                            end
                        end

                    rescue => error
                        puts error
                        puts "The shit down while message parsing"
                    end
                end
            end
        end
    rescue => error
        puts error
        puts "The shit down cause a api error"
    end
end
