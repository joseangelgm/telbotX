#!/usr/bin/ruby

require 'pry-byebug'

$LOAD_PATH << __dir__ + '/src/'

require 'modules/logger'
require 'modules/dataUtils'
include Logger
include DataUtils

require 'optparse'
require 'timeout'
require 'open3'

VERSION_NUMBER = "1.0"

LOCATION_PID_FILES = "/tmp/"
UPDATER_PID_FILE   = "#{LOCATION_PID_FILES}updaterTelbotX.pid"
SCHED_PID_FILE     = "#{LOCATION_PID_FILES}schedTelbotX.pid"

UPDATER_EXE = "#{__dir__}/updaterLauncher.rb"
SCHED_EXE   = "#{__dir__}/schedLauncher.rb"

UPDATER_TIMEOUT = 10 #seconds
SCHED_TIMEOUT   = 15 #seconds

UPDATER_ELEM = {
    :name     => "Updater",
    :exe      => UPDATER_EXE,
    :pid_file => UPDATER_PID_FILE,
    :timeout  => UPDATER_TIMEOUT
}

SCHED_ELEM = {
    :name     => "Sched",
    :exe      => SCHED_EXE,
    :pid_file => SCHED_PID_FILE,
    :timeout  => SCHED_TIMEOUT
}

# command
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

def format_param_structure(params)

    array_params = []

    case params
    when Hash;
        params.each do |k, v|
            array_params << v
        end
    when Array;
        array_params = params
    else
        puts "Parameters could be recognize to format"
        exit 1
    end
    array_params
end

def command(optparse, param, &block)
    # the * character is used to convert an array to argument list of a function
    optparse.on(*format_param_structure(param), block)
end

def create_pid_file(path_file, pid)
    File.open(path_file, 'w') do |f|
        f.write(pid)
    end
end

def check_if_process_launched(pid_file)
    # check in that way is not exactly correct
    if File.file?(pid_file)
        pid_to_check = nil
        File.open(pid_file, 'r') do |f|
            f.each_line do |line|
                pid_to_check = line
            end
        end
        stdout, stderr, status = Open3.capture3("ps -p #{pid_to_check}")
        if status.exitstatus == 0
            return true
        else
            if !stderr.empty?
                puts "An error ocurred when killing process in #{pid_file} #{stderr}"
                exit 1
            end
        end
    else
        return false
    end
end

def kill_process(pid_file)
    pid_to_kill = nil
    if File.file? pid_file
        File.open(pid_file, 'r') do |f|
            f.each_line do |line|
                pid_to_kill = line
            end
        end

        stdout, stderr, status = Open3.capture3("kill -s SIGINT #{pid_to_kill}")
        if status.exitstatus == 0
            puts "#{pid_file} killed"
            Logger::log_message :info, "#{pid_file} killed"
            %x{rm #{pid_file}}
        else
            if !stderr.empty?
                puts "There was a problem killin process #{pid_to_kill} #{stderr}"
                exit 1
            end
        end
    else
        puts "#{pid_file} doesnt exists"
    end
end

# element => hashmap
# block => if we have to launch something after
def launch_element(element, &block)
    if check_if_process_launched element[:pid_file]
        puts "#{element[:name]} already launched"
        block.call if block_given?
    else
        # create a pipe
        reader, writer = IO.pipe
        # flush automatically
        writer.sync = true
        pid = Process.spawn element[:exe], :out=>writer
        # dont let the process zombie
        Process.detach pid
        writer.close # not write
        Logger::log_message :info, "#{element[:name]} launched. PID #{pid}"
        puts "#{element[:name]} launched. PID #{pid}"
        create_pid_file element[:pid_file], pid
        response = nil
        begin
            Timeout::timeout(element[:timeout]) do
                response = reader.gets # until we receive data from subprocess
            end
        rescue Exception => e # Timeout reached
            puts "Shutting down due to reach #{element[:name]} timeout"
            kill_process element[:pid_file]
        ensure
            reader.close
        end

        if !response.nil?
            response = DataUtils::eval_to_hashmap response # transform response to hashmap
            if response[:exit] != 0
                puts "Failing launching #{element[:name]}...Shutting down"
                exit 1
            else
                block.call if block_given?
            end
        else
            puts "Failing launching #{element[:name]}...Shutting down"
            exit 1
        end
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

command optparse, POWEROFF do |elements|
    if elements.nil?
        puts "You have to provide what elems you want to poweroff..."
        puts optparse
        exit 1
    else
        options[:poweroff] = []
        elements.each do |elem|
            case elem.downcase
            when 's', 'sched'
                options[:poweroff].unshift SCHED_ELEM[:pid_file]
            when 'u', 'updater'
                options[:poweroff] << UPDATER_ELEM[:pid_file]
            else
                puts "Invalid option #{elem}"
                puts optparse
                exit 1
            end
        end
        options[:poweroff].each do |pid_file|
            kill_process pid_file
        end
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
        Logger::log_message :info, "Starting telBotX. Version #{VERSION_NUMBER}"
        if options[:sched]
            launch_element SCHED_ELEM do
                launch_element UPDATER_ELEM
            end
        elsif options[:updater]
            launch_element UPDATER_ELEM
        end
    end
end