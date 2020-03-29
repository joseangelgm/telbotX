#!/usr/bin/env ruby

$LOAD_PATH << __dir__ + '/src/'

STDIN.close #we only will write through the pipe

require 'modules/fileUtils'
require 'modules/logger'
include Logger # to log in case of exception
include FileUtils

# nedeed libaries and code
begin
    require 'yaml'
    require 'updater'
    Logger::log_message :info, "Libraries and code needed for updater were required properly..."
rescue Exception => e
    Logger::log_message :error, "Libraries needed for updater could not be found...Sutting down:", e
    exit 1
end

CONFIG_FOLDER  = "#{__dir__}/src/config/"
BOT_CONFIG     = "#{CONFIG_FOLDER}bot.yaml"
UPDATER_CONFIG = "#{CONFIG_FOLDER}updater.yaml"

config = FileUtils::load_from_file BOT_CONFIG
Logger::log_message :info, "Config for bot.yaml", config

updater_config = FileUtils::load_from_file UPDATER_CONFIG
Logger::log_message :info, "Config for updater", updater_config

num_retry = 1
launched  = false
exception = nil
updater = Updater.new("#{config[:bot_url]}#{config[:bot_token]}", updater_config[:ip], updater_config[:port])
while !launched && num_retry <= updater_config[:retries]
    begin
        Logger::log_message :info, "Attemp #{num_retry} trying launch updater"
        updater.create_socket
        launched = true
    rescue Exception => e
        num_retry += 1
        exception = e
        sleep updater_config[:time_to_wait]
    end
end

if !launched
    Logger::log_message :error, "Updater could not be launched", exception
    STDOUT.puts "{:exit => 1}"
    STDOUT.close
    exit 1
end

STDOUT.puts "{:exit => 0}"
STDOUT.close

# SIGINT = 2
trap("SIGINT") do
    signal_thread = Thread.new do
        log_message(:info, "Receive SIGINT")
        updater.poweroff_socket
    end
    signal_thread.join
end

main_thread = Thread.new { updater.run }
main_thread.join