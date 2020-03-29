#!/usr/bin/env ruby

$LOAD_PATH << __dir__ + '/src/'

STDIN.close # PIPE: we only will write through the pipe, just in case

require 'modules/fileUtils'
require 'modules/logger'

include Logger
include FileUtils

# nedeed libaries and code
begin
    require 'yaml'
    require 'sched'
    Logger::log_message :info, "Libraries and code needed for sched were required properly..."
rescue Exception => e
    Logger::log_message :error, "Libraries needed for sched could not be found...Sutting down:", e
    exit 1
end

CONFIG_FOLDER = "#{__dir__}/src/config/"
SCHED_CONFIG  = "#{CONFIG_FOLDER}sched.yaml"

sched_config = FileUtils::load_from_file SCHED_CONFIG
Logger::log_message :info, "Config for sched", sched_config

num_retry = 1
launched  = false
exception = nil
sched     = Sched.new(sched_config[:ip], sched_config[:port])
while !launched && num_retry <= sched_config[:retries]
    begin
        Logger::log_message :info, "Attemp #{num_retry} trying launch sched"
        sched.create_socket
        launched = true
    rescue Exception => e
        num_retry += 1
        exception = e
        sleep sched_config[:time_to_wait]
    end
end

if !launched
    Logger::log_message :error, "Sched could not be launched", exception
    STDOUT.puts "{:exit => 1}"
    STDOUT.close
    exit 1
end

STDOUT.puts "{:exit => 0}"
STDOUT.close

sched.run