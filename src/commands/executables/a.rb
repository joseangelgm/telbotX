require 'shellwords'

command = "./time"
args = "-d -t"

str = ""
args.split(' ').each do |elem|
    str << "'#{elem}' "
end

puts %x("#{command}" #{str})