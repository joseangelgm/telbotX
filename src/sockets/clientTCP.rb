require 'socket'
require 'base64'

class ClientTCP

    attr_reader :port
    attr_reader :ip

    def initialize(ip, port)
        @socket = TCPSocket.open(ip, port)
        @ip   = @socket.addr[2]
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

    def close
        @socket.close
    end

end