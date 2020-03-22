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
        @bot_url = "#{bot_url}/#{GET_UPDATES}"
        @socket  = ClientTCP.new ip, port
        log_message(:info, "Updater create socket on #{@socket.ip} ip, port #{@socket.port}")
    end

    def run

        loop {

            response = make_query(@bot_url, :post, {})
            commands = response[:body][:result]

            message = {
                :status => response[:status],
                :num_messages => commands.count
            }

            log_message(:info, "Command #{GET_UPDATES}", message)

            commands.each do |command|
                log_message(:info, "Command #{command[:message][:text]} executing command TEST..")
                sleep 2
            end
            sleep 5
        }
        @socket.close
    end

end