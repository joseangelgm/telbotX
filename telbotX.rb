#!/usr/bin/env ruby

require 'pry-byebug'

$LOAD_PATH << __dir__ + '/src/'

require 'modules/logger'
include Logger

require 'optparse'
require 'timeout'

VERSION_NUMBER     = "1.0"

LOCATION_PID_FILES = "/tmp/"
UPDATER_PID_FILE   = "updaterTelbotX.pid"
SCHED_PID_FILE     = "schedTelbotX.pid"

UPDATER_EXE        = "#{__dir__}/updaterLauncher.rb"
SCHED_EXE          = "#{__dir__}/schedLauncher.rb"

TIMEOUT_UPDATER = 10 #seconds

UPDATER = {
    :short => "-u",
    :large => "--updater",
    :help  => "Launch updater"
}

SCHED = {
    :short => "-s",
    :large => "--sched",
    :help  => "Launch sched"
}

POWEROFF = {
    :short => "-p",
    :large => "--poweroff [sched],[updater]",
    :help  => "Poweroff elements",
    :type  => Array
}

VERSION = {
    :short => "-v",
    :large => "--version",
    :help  => "Print version number"
}

HELP = {
    :short => "-h",
    :large => "--help",
    :help  => "Display this help",
}

def format_param_structure(param)

    array_params = []

    case param
    when Hash;
        param.each do |k, v|
            array_params << v
        end
    else
        puts "#{param} could be recognize to format"
        exit 1
    end
    array_params
end

def command(optparse, param, &block)
    # the * character is used to convert an array to argument list of a function
    optparse.on(*format_param_structure(param), block)
end

def create_pid_file(elem, pid)
    path_file = nil
    if elem == :sched
        path_file = "#{LOCATION_PID_FILES}#{SCHED_PID_FILE}"
    elsif elem == :updater
        path_file = "#{LOCATION_PID_FILES}#{UPDATER_PID_FILE}"
    else
        return nil
    end
    File.open(path_file, 'w') do |f|
        f.write(pid)
    end
end

def check_if_process_launched(elem)
    launched = false
    if elem == :sched
        launched = File.file?(SCHED_FILE)
    elsif elem == :updater
        launched = File.file?(UPDATER_FILE)
    end
    launched
end

def kill_process(elem)
    path_file = nil
    if :updater
        path_file = "#{LOCATION_PID_FILES}#{UPDATER_PID_FILE}"
    elsif :sched
        path_file = "#{LOCATION_PID_FILES}#{SCHED_PID_FILE}"
    else
        return nil
    end

    pid_to_kill = nil
    File.open(path_file, 'r') do |f|
        f.each_line do |line|
            pid_to_kill = line
        end
    end
    puts "Killing #{elem}"
    pid = Process.spawn "kill -9 #{pid_to_kill}"
end

def launch_updater
    Logger::log_message :info, "Launching updater..."
    puts "Launching Updater..."
    # create a pipe
    reader, writer = IO.pipe
    # flush automatically
    writer.sync = true
    pid = Process.spawn UPDATER_EXE, :out=>writer
    # dont let the process zombie
    Process.detach pid
    writer.close # not write
    create_pid_file :updater, pid

    response = nil
    begin
        Timeout::timeout(TIMEOUT_UPDATER) do
            response = reader.gets # until we receive data from subprocess
        end
    rescue Exception => e # Timeout reached
        puts "Shutting down due to reach updater timeout"
        kill_process :updater
        exit 1
    ensure
        reader.close
    end

    response = eval(response) # response to hashmap
    if response[:exit] != 0
        puts "Failing launching updater...Shutting down"
        exit response[:exit]
    else
        puts "Updater launched"
    end
end

options = {}
optparse = OptionParser.new

command optparse, UPDATER do
    options[:updater] = true
end

command optparse, SCHED do
    options[:sched] = true
end

command optparse, POWEROFF do |m|
    binding.pry
    if m.nil?
        puts "You have to provide what elems you want to poweroff..."
        puts optparse
        exit 1
    else
        options[:elems] = m
    end
end

command optparse, VERSION do
    puts "Version #{VERSION_NUMBER}"
end

command optparse, HELP do
    puts optparse
end

argv_size = ARGV.length

optparse.parse! ARGV

if argv_size == 0
    puts optparse
    exit 1
else
    if options[:sched] || options[:updater]
        #move log file and create new one if it is needed
        Logger::create_log_file_if_necessary

        # if lauch sched, then we have to launch updater
        # if not launch updater only
        if options[:sched]
            puts "Launch sched"
            #launch sched
            if options[:updater]
            end
        end
        if options[:updater]
            launch_updater
        end
    end
end