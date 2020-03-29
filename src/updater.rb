#because is launched from updaterLauncher.rb the paths are like following.
require 'sockets/clientTCP'

require 'modules/logger'
require 'modules/queryHTTP'
require 'modules/dataUtils'

class Updater

    include Logger
    include QueryHTTP
    include DataUtils

    GET_UPDATES = "getUpdates"
    private_constant :GET_UPDATES

    public

    def initialize(bot_url, ip, port)
        @bot_url  = "#{bot_url}/#{GET_UPDATES}"

        @ip       = ip
        @port     = port

        @poweroff = false
        @mutex_poweroff = Mutex.new

        @tasks = {}
        @mutex_tasks = Mutex.new
    end


    def create_socket
        @socket  = ClientTCP.new @ip, @port
        log_message :info, "Updater create socket on #{@socket.ip} ip, port #{@socket.port}"
    end

    def poweroff_socket
        @mutex_poweroff.synchronize do
            @poweroff = true
        end
    end

    def run
        while !poweroff_state do
            commands = get_updates
            commands.each do |command|
                command_parsed = filter_telegram_message command
                log_message :info, "Sending command:", command_parsed
                @socket.send_message command[:message][:text]
                sleep 2
            end
            sleep 20
        end
        @socket.send_message "BYE"
        @socket.close
        log_message :info, "Poweroff updater..."
    end

    private

    def poweroff_state
        poweroff = false
        @mutex_poweroff.synchronize do
            poweroff = @poweroff
        end
        poweroff
    end

    def get_updates
        response = make_query(@bot_url, :post, {})
        message = {
            :status      => response[:status],
            :telegram_ok => response[:body][:ok],
        }
        ok = response[:body][:ok]
        commands = []
        if ok
            commands = response[:body][:result]
        end
        message[:num_commands] = commands.count
        log_message :info, "Command #{GET_UPDATES}", message
        commands
    end

end