#!/usr/bin/env ruby

$LOAD_PATH << Dir.pwd + '/src/'

require 'pry-byebug'

require 'updater'

require 'modules/logger'
include Logger

#move log file and create new one if it is needed
Logger::create_log_file_if_new_day

begin
    require 'yaml'
    Logger::log_message :info, "Libraries required installed..."
rescue Exception => e
    Logger::log_message :error, "Libraries needed could not be found...Sutting down: #{e.message}"
    exit 1
end

CONFIG_FOLDER = "#{Dir.pwd}/src/config/"

Logger::log_message :info, "Loading config..."

config = YAML.load_file("#{CONFIG_FOLDER}bot.yaml")
Logger::log_message :info, "Config from bot.yaml", config

Logger::log_message :info, "Launching elements..."

updater = Updater.new("#{config[:bot_url]}#{config[:bot_token]}")