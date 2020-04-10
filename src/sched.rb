require 'sockets/serverTCP'

require 'modules/logger'

class Sched

    include Logger

    def initialize(ip, port)
        @ip     = ip
        @port   = port
        @socket = nil

    end

end