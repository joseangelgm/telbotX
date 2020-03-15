require 'socket'
require 'base64'

class ClientTCP

    attr_reader :port
    attr_reader :host

    def initialize(host, port)
        @socket = TCPSocket.open(host, port)
        @host   = @socket.addr[2]
        @port   = @socket.addr[1]
    end

    def send_message(message)
        message_encoded = Base64.encode64(message)
        @socket.puts(message_encoded)
    end

    def read_message
        message_encoded = @socket.gets
        return Base64.decode64(message_encoded)
    end

end