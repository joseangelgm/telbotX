require 'sockets/serverTCP'

require 'modules/logger'

class Sched

    include Logger

    def initialize(ip, port)
        @ip     = ip
        @port   = port
        @socket = nil

        @poweroff = false
        @mutex_poweroff = Mutex.new

        @tasks = {}
        @mutex_tasks = Mutex.new
    end

    def create_socket
        @socket = ServerTCP.new @ip, @port
        log_message(:info, "Sched create server socket on #{@socket.ip} ip, port #{@socket.port}")
    end

    def poweroff_state
        @mutex_poweroff.synchronize do
            return @poweroff
        end
    end

    def run
        client = @socket.accept #just one client
        while !poweroff_state do
            message = @socket.read_message client
            if message == "BYE"
                poweroff_socket
            end
            log_message :info, "Sched: receive command #{message}"
        end
        @socket.close
        log_message :info, "Sched socket closed"
    end

    private
    def poweroff_socket
        @mutex_poweroff.synchronize do
            @poweroff = true if !@poweroff
        end
    end
end