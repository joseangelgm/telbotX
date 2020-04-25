#!/usr/bin/env ruby

require 'optparse'

def hash_to_array(hash)
    array = []
    hash.each do |k, v|
        array << v
    end
    array
end

def add_parse_option(command_parser_map, option, &block)
    return "No block given" unless block_given?
    # the * character is used to convert an array to argument list of a function
    command_parser_map.on(*hash_to_array(option), block)
end

FILE = {
    :short => "-l",
    :large => "--logfile FILE",
    :help  => "Write log to FILE",
    :type  => String
}

NUMBER = {
    :short => "-n",
    :large => "--number [NUMBER],...",
    :help  => "Get number",
    :type  => Array
}

HELP = {
    :short => "-h",
    :large => "--help",
    :help  => "Display help",
}

options = {}

optparse = OptionParser.new

add_parse_option(optparse, FILE) do |file|
    options[:file] = file
end

add_parse_option(optparse, NUMBER) do |number|
    options[:number] = number
end

add_parse_option(optparse, HELP) do
    puts optparse
end

optparse.parse!

puts options