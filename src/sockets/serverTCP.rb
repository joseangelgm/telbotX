require 'socket'
require 'base64'

class ServerTCP

    attr_reader :port
    attr_reader :ip

    def initialize(ip, port)
        @socket = TCPServer.open(ip, port)
        @ip   = @socket.addr[2]
        @port   = @socket.addr[1]
    end

    def send_message(client, message)
        message_encoded = Base64.encode64(message)
        client.puts(message_encoded)
    end

    def read_message(client)
        message_encoded = client.gets
        return Base64.decode64(message_encoded)
    end

    def accept
        return @socket.accept
    end

    def close
        @socket.close
    end
end