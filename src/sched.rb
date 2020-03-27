require 'sockets/serverTCP'

require 'modules/logger'

class Sched

    include Logger

    def initialize(ip, port)
        @ip     = ip
        @port   = port
        @socket = nil
    end

    def create_socket
        @socket = ServerTCP.new @ip, @port
        log_message(:info, "Sched create server socket on #{@socket.ip} ip, port #{@socket.port}")
    end

    def run
        @socket.close
    end

end