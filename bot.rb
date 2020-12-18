require 'telegram/bot'
require 'dotenv/load'
require 'mysql2'
require 'colorize'

class Database
	def initialize
		begin
			@db = Mysql2::Client.new(
				host: ENV['DB_HOST'],
				username: ENV['DB_USERNAME'],
				password: ENV['DB_PASSWORD'],
				database: ENV['DB_NAME']
			)
			puts "DB connected".green
		rescue Mysql2::Error
			puts "DB not connected".red
		end
	end

	def create_or_update_user(id)
		is_exist = @db.query("SELECT * FROM users WHERE id = #{id};").to_a
		if is_exist.any?
			count = is_exist[0]["count"]
			@db.query("UPDATE users SET count = #{count + 1} WHERE id = #{id};")
		else
			@db.query("INSERT INTO users (`id`, `count`) VALUES (#{id}, 1);")
		end
	end
end

class Bot
	def initialize(database, fortunes)
		@token = ENV['TELEGRAM_BOT_TOKEN']
		@database = database || nil
		@fortunes = fortunes || []
	end

	def run
		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |bot_request|
				puts "Bot listen".green
				puts
				Thread.start(bot_request) do |request|
					kb     = [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🧡 Предсказание 🧡', callback_data: 'oracle')]
					markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
					begin
						if request.instance_of? Telegram::Bot::Types::CallbackQuery
							case request.data
							when 'oracle'
								send_fortune(bot, request, markup)
							end
						end
						if request.instance_of? Telegram::Bot::Types::Message
							case request.text
							when '/start'
								start(bot, request, markup)
							end
						end
					rescue => e
						puts e
						puts "The shit down while message parsing"
					end
				end
			end
		end
	end

	def start(bot, request, markup)
		puts "Client (#{request.chat.id}): /start"
		bot.api.send_message(
			chat_id: request.chat.id,
			text: "Привет, #{request.from.first_name}!\nТы можешь узнать предсказание при помощи кнопки внизу!",
			reply_markup: markup
		)
	end

	def send_fortune(bot, request, markup)
		puts "Client (#{request.from.id}) asks a fortune"
		@database.create_or_update_user(request.from.id) if @client
		fortune = ""
		while fortune.length < 3
			@fortunes.shuffle!
			fortune = @fortunes[0].strip
		end
		puts "Fortune: #{fortune}"
		puts ""
		bot.api.send_message(
			chat_id: request.from.id,
			parse_mode: 'markdown',
			text: "*Твоё будущее:*\n\n#{fortune}",
			reply_markup: markup
		)
	end
end

text_url = File.join(File.dirname(__FILE__), "/text.txt")
fortunes = File.open(text_url).read.split(/\n|\./)
puts "#{fortunes.size} sentences loaded".green

database = Database.new
Kernel.loop do
	bot = Bot.new(database, fortunes)
	bot.run
end
