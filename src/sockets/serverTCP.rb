require 'socket'

class ServerTCP

    attr_reader :port
    attr_reader :ip

    def initialize(ip, port)
        @socket = TCPServer.open(ip, port)
        @ip     = @socket.addr[2]
        @port   = @socket.addr[1]
    end

    def send_message(client, message)
        client.puts(message)
    end

    def read_message(client)
        message = client.gets
        return message
    end

    def accept
        return @socket.accept
    end

    def close
        @socket.close
    end
end