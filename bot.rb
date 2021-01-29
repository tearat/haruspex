require 'telegram/bot'
require 'dotenv/load'
# require 'mysql2'
require 'colorize'
require 'optparse'

require './classes/database_class'
require './classes/bot_class'

options = {}
OptionParser.new do |opts|
  opts.on("-db", "--database", "Run with database") do
    options[:db] = true
  end
end.parse!

text_path = File.join(File.dirname(__FILE__), "/text.txt")
fortunes = File.open(text_path).read.split(/\n|\./)

# puts "#{fortunes.size} sentences loaded".green

database = options.key?(:db) ? Database.new : nil

bot = Bot.new(database, fortunes)
bot.run
