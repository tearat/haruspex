class Database
	def initialize
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
