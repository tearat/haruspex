class Bot
	def initialize(database, fortunes)
		log "\n"
		unless fortunes.any?
			log "FATAL: Sentences not provided. Exit"
			abort
		end
		if database
			@database = Database
		else
			log "WARNING: Database not connected"
		end
		@fortunes = fortunes || []
		log "#{fortunes.size} sentences provided to bot"
		@token = ENV['TELEGRAM_BOT_TOKEN']
	end

	def run
		log "Bot starts"
		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |bot_request|
				# log "Request"
				Thread.start(bot_request) do |request|
					kb     = [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🧡 Предсказание 🧡', callback_data: 'oracle')]
					markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
					begin
						if request.instance_of? Telegram::Bot::Types::CallbackQuery
							log "Request from [#{request.from.id}] is CallbackQuery [#{request.data}]"
							case request.data
							when 'oracle'
								send_fortune(bot, request, markup)
							end
						end

						if request.instance_of? Telegram::Bot::Types::Message
							log "Request from [#{request.from.id}] is Message [#{request.text}]"
							case request.text
							when '/start'
								start(bot, request, markup)
							end
						end
					rescue => e
						log "FATAL: App down while message parsing (#{e})"
					end
				end
			end
		end
	end

	def start(bot, request, markup)
		bot.api.send_message(
			chat_id: request.chat.id,
			text: "Привет, #{request.from.first_name}!\nТы можешь узнать предсказание при помощи кнопки внизу!",
			reply_markup: markup
		)
	end

	def send_fortune(bot, request, markup)
		# @database.create_or_update_user(request.from.id) if @database
		fortune = ""
		while fortune.length < 3
			@fortunes.shuffle!
			fortune = @fortunes[0].strip
		end
		log "Sent fortune to [#{request.from.id}]: #{fortune}"
		bot.api.send_message(
			chat_id: request.from.id,
			parse_mode: 'markdown',
			text: "*Твоё будущее:*\n\n#{fortune}",
			reply_markup: markup
		)
	end

	def log(text)
		logger = File.open("history.log", "a")
		logger.write "#{Time.now}: #{text} \n"
		logger.close
	end
end
