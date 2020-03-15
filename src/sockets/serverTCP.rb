require 'socket'
require 'base64'

class ServerTCP

    attr_reader :port
    attr_reader :host

    def initialize(host, port)
        @socket = TCPServer.open(host, port)
        @host   = @socket.addr[2]
        @port   = @socket.addr[1]
    end

    def do_loop(&block)
        block.call
    end

end