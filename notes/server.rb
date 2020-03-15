#!/usr/bin/env ruby

require 'socket'

hostname = 'localhost'
port = 8686

server = TCPServer.open(hostname, port)

=begin
loop {
    client = server.accept # wait for a client to connect
    client.puts("Connectioooooon") # send message
    client.puts("Closing...") # send message
    client.close
}
=end

client = server.accept # wait for a client to connect
client.puts("Connectioooooon")
client.puts("Closing...")
client.close

server.close