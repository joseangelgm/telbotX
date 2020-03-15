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

    def do_loop(&block)
        block.call
    end

end