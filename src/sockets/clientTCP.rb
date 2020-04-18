require 'socket'

class ClientTCP

    attr_reader :port
    attr_reader :ip

    def initialize(ip, port)
        @socket = TCPSocket.open(ip, port)
        @ip     = @socket.addr[2]
        @port   = @socket.addr[1]
    end

    def send_message(message)
        @socket.puts(message)
    end

    def read_message
        message = @socket.gets
        return message
    end

    def close
        @socket.close
    end

end