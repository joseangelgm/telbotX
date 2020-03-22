#!/usr/bin/env ruby

$LOAD_PATH << __dir__ + '/src/'

STDIN.close #we only wil write through the pipe

require 'modules/fileUtils'
require 'modules/logger'
include Logger # to log in case of exception
include FileUtils

# nedeed libaries and code
begin
    require 'yaml'
    require 'updater'
    Logger::log_message :info, "Libraries and code needed for updater imported properly..."
rescue Exception => e
    # review with new implementation
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
updater   = nil
exception = nil

while !launched && num_retry <= updater_config[:retries]
    begin
        Logger::log_message :info, "Attemp #{num_retry} trying launch updater"
        updater = Updater.new("#{config[:bot_url]}#{config[:bot_token]}", updater_config[:ip], updater_config[:port])
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
thread_update = Thread.new {updater.run}
STDOUT.puts "{:exit => 0}"
STDOUT.close
thread_update = Thread.new { updater.run }
thread_update.join # wait until thread_update finish