#because is launched from updaterLauncher.rb the paths are like following.
require 'sockets/clientTCP'

require 'modules/logger'
require 'modules/queryHTTP'
require 'modules/telegramUtils'
require 'modules/dataUtils'

class Updater

    include Logger
    include QueryHTTP
    include TelegramUtils
    include DataUtils

    GET_UPDATES = "getUpdates"
    private_constant :GET_UPDATES

    attr_reader :update_id

    public

    def initialize(bot_url, ip, port, update_id)
        @bot_url  = "#{bot_url}/#{GET_UPDATES}"

        @clientSocket = nil
        @ip = ip
        @port = port

        @update_id         = update_id
        @last_command_id   = update_id #last command saved after getting updates

        @poweroff = false
        @m_poweroff = Mutex.new

        @command_ids  = []
        @commands_info = {}
        @m_commands = Mutex.new

        # threads
        @thread_updates  = nil
        @thread_sender   = nil
        @thread_receiver = nil

    end

    def create_socket
        if @clientSocket.nil?
            @clientSocket = ClientTCP.new(@ip, @port)
            log_message :info, "Socket created", {:ip => @ip, :port => @port}
        end
    end

    def run
        begin
            @thread_updates  = thread_updates
            @thread_sender   = thread_sender
            @thread_receiver = thread_receiver

            # if updates ends, all thread must die. It doesn't make sense
            # keep sending information
            # also keep receiver to wait poweroff from sched
            @thread_updates.join
            #@thread_sender.join
            @thread_receiver.join
        rescue => exception
            log_message :debug, "Exception UPDATER", exception
        ensure
            @clientSocket.close
        end
    end

    private

    ## get the value of @poweroff
    def get_poweroff
        poweroff = false
        @m_poweroff.synchronize do
            poweroff = @poweroff
        end
        poweroff
    end

    ### set @poweroff = true
    def poweroff_updater
        @m_poweroff.synchronize do
            @poweroff = true
        end
    end

    # THREADS SECTION
    def thread_updates
        thread = Thread.new do
            while !get_poweroff do
                #get updates
                bot_message = make_query(@bot_url, :post, {})
                if bot_message.nil?
                    log_message :error, "#{GET_UPDATES}: retrieve null...retrying"
                elsif bot_message[:status] != "200" #success http = 200
                    log_message :error, "#{GET_UPDATES}: http status is #{bot_message[:status]}...retrying"
                elsif !bot_message[:body][:ok]
                    log_message :error, "#{GET_UPDATES}: telegram ok is false...retrying"
                else
                    log_message :info, "#{GET_UPDATES}: processing commands..."
                    commands = bot_message[:body][:result]
                    new_commands = 0
                    commands.each do |command|
                        update_id = command[:update_id]
                        if @last_command_id < update_id
                            @m_commands.synchronize do
                                @command_ids << update_id
                                @commands_info[update_id] = update_to_command command
                                new_commands += 1
                            end
                            @last_command_id = update_id
                        end
                    end
                    log_message :info, "#{GET_UPDATES}: new commands = #{new_commands}. Total commands to process #{@command_ids.count}"
                end
                sleep 10
            end
        end
        thread
    end

    def thread_sender
        thread = Thread.new do
            while !get_poweroff do
                command = nil
                @m_commands.synchronize do
                    update_id = @command_ids.first
                    if !update_id.nil?
                        #remove the element and return it
                        command = @commands_info.delete(update_id)
                        @command_ids.shift(1)
                    end
                end
                if !command.nil?
                    @clientSocket.send_message command
                    log_message :info, "Command sended to sched with id #{command[:update_id]}", command
                    sleep 2
                end
            end
        end
        thread
    end

    def thread_receiver
        thread = Thread.new do
            while !get_poweroff do
                response = @clientSocket.read_message
                if !response.nil?
                    response = eval_to_hashmap(response)
                    if response.key?(:poweroff) and response[:poweroff]
                        poweroff_updater
                        log_message :info, "Powering off updater...", response
                    else
                        log_message :info, "Received response from sched with id #{response[:update_id]}", response
                        @update_id = response[:update_id]
                        sleep 2
                    end
                end
            end
        end
        thread
    end
end