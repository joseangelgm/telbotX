#!/usr/bin/env ruby

STDOUT.close
output = "No changed"
t = Thread.new do
    command = "ls"
    output = %x("#{command}")
end

t.join