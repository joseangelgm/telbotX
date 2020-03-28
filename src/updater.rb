#because is launched from updaterLauncher.rb the paths are like following.
require 'sockets/clientTCP'

require 'modules/logger'
require 'modules/queryHTTP'

class Updater

    include Logger
    include QueryHTTP

    GET_UPDATES = "getUpdates"
    private_constant :GET_UPDATES

    def initialize(bot_url, ip, port)
        @bot_url  = "#{bot_url}/#{GET_UPDATES}"
        @ip       = ip
        @port     = port
        @poweroff = false
        @mutex_poweroff = Mutex.new
    end


    def create_socket
        @socket  = ClientTCP.new @ip, @port
        log_message(:info, "Updater create socket on #{@socket.ip} ip, port #{@socket.port}")
    end

    def poweroff_socket
        @mutex_poweroff.synchronize do
            @poweroff = true if !@poweroff
        end
    end

    def run
        while !poweroff_state do

            response = make_query(@bot_url, :post, {})
            commands = response[:body][:result]

            message = {
                :status => response[:status],
                :num_messages => commands.count
            }

            log_message(:info, "Command #{GET_UPDATES}", message)

            commands.each do |command|
                log_message(:info, "Sending command #{command[:message][:text]} ")
                @socket.send_message command[:message][:text]
                sleep 2
            end
            sleep 5
        end
        @socket.close
    end

    private

    def poweroff_state
        @mutex_poweroff.synchronize do
            return @poweroff
        end
    end

end