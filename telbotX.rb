#!/usr/bin/env ruby

$LOAD_PATH << Dir.pwd + '/src/'

require 'pry-byebug'

require 'updater'

require 'modules/fileUtils'
require 'modules/logger'

include Logger
include FileUtils
binding.pry
#move log file and create new one if it is needed
Logger::create_log_file_if_necessary

Logger::log_message :info, "Starting telbotX!!"

begin
    require 'yaml'
    Logger::log_message :info, "Libraries required are installed..."
rescue Exception => e
    Logger::log_message :error, "Libraries needed could not be found...Sutting down: #{e.message}"
    exit 1
end

CONFIG_FOLDER = "#{Dir.pwd}/src/config/"
BOT_CONFIG    = "#{CONFIG_FOLDER}bot.yaml"

Logger::log_message :info, "Loading config..."
config = FileUtils::load_from_file(BOT_CONFIG)
Logger::log_message :info, "Config from bot.yaml", config

Logger::log_message :info, "Launching elements..."

updater = Updater.new("#{config[:bot_url]}#{config[:bot_token]}", "127.0.0.1", 14000)
thread_update = Thread.new {updater.run}
thread_update.join