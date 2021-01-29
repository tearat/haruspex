class Bot
	def initialize(database, fortunes)
		log "\n"
		unless fortunes.any?
			log "#{Time.now}: FATAL: Sentences not provided. Exit \n"
			abort
		end
		if database
			@database = Database
		else
			log "#{Time.now}: WARNING: Database not connected \n"
		end
		@fortunes = fortunes || []
		log "#{Time.now}: #{fortunes.size} sentences provided to bot \n"
		@token = ENV['TELEGRAM_BOT_TOKEN']
	end

	def run
		log "#{Time.now}: Bot run \n"
		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |bot_request|
				log "#{Time.now}: Bot request \n"
				Thread.start(bot_request) do |request|
					kb     = [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🧡 Предсказание 🧡', callback_data: 'oracle')]
					markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
					begin
						if request.instance_of? Telegram::Bot::Types::CallbackQuery
							log "#{Time.now}: Bot request is CallbackQuery \n"
							case request.data
							when 'oracle'
								send_fortune(bot, request, markup)
							end
						end

						if request.instance_of? Telegram::Bot::Types::Message
							log "#{Time.now}: Bot request is Message \n"
							case request.text
							when '/start'
								start(bot, request, markup)
							end
						end
					rescue => e
						log "#{Time.now}: FATAL: App down while message parsing (#{e}) \n"
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
		log "#{Time.now}: Sent fortune to #{request.from.id}: #{fortune} \n"
		bot.api.send_message(
			chat_id: request.from.id,
			parse_mode: 'markdown',
			text: "*Твоё будущее:*\n\n#{fortune}",
			reply_markup: markup
		)
	end

	def log(text)
		logger = File.open("history.log", "a")
		logger.write text
		logger.close
	end
end
