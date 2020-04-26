#because is launched from updaterLauncher.rb the paths are like following.
require 'sockets/clientTCP'

require 'modules/logger'
require 'modules/queryHTTP'
require 'modules/telegramUtils'
require 'modules/dataUtils'

include QueryHTTP
include Logger
include TelegramUtils
include DataUtils

class Updater

    attr_reader :update_id

    public

    def initialize(bot_url, ip, port, update_id)
        @bot_methods = {
            :updates => "getUpdates",
            :send_message  => "sendMessage"
        }
        @bot_url  = bot_url

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
            Logger::log_message :info, "Socket created", {:ip => @ip, :port => @port}
        end
    end

    def run
        begin
            @thread_updates  = thread_updates
            @thread_sender   = thread_sender
            @thread_receiver = thread_receiver

            @thread_updates.report_on_exception  = false
            @thread_sender.report_on_exception   = false
            @thread_receiver.report_on_exception = false

            # if updates ends, all thread must die. It doesn't make sense
            # keep sending information
            # also keep receiver to wait poweroff from sched
            @thread_updates.join
            #@thread_sender.join
            @thread_receiver.join
        rescue Exception => e
            Logger::log_message :info, "Exception Updater powering off...Not important", e
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

    # Improve thread_updates to request only when @updat_id
    # and last_command_id are equals. It means that we have already
    # process all commands.
    def thread_updates
        thread = Thread.new do
            while !get_poweroff do
                begin
                    #get updates
                    bot_message = make_query("#{@bot_url}/#{@bot_methods[:updates]}", :post, {})
                    if bot_message.nil?
                        Logger::log_message :error, "#{@bot_methods[:updates]}: retrieve null...retrying"
                    elsif bot_message[:status] != "200" #success http = 200
                        Logger::log_message :error, "#{@bot_methods[:updates]}: http status is #{bot_message[:status]}...retrying"
                    elsif !bot_message[:body][:ok]
                        Logger::log_message :error, "#{@bot_methods[:updates]}: telegram ok is false...retrying"
                    else
                        Logger::log_message :info, "#{@bot_methods[:updates]}: processing commands..."
                        commands = bot_message[:body][:result]
                        new_commands = 0
                        commands.each do |command|
                            update_id = command[:update_id]
                            if @last_command_id < update_id
                                @m_commands.synchronize do
                                    @command_ids << update_id
                                    @commands_info[update_id] = TelegramUtils::update_to_command command
                                    new_commands += 1
                                end
                                @last_command_id = update_id
                            end
                        end
                        Logger::log_message :info, "#{@bot_methods[:updates]}: new commands = #{new_commands}. Total commands to process #{@command_ids.count}"
                    end
                    sleep 10
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_updates", e
                end
            end
        end
        thread
    end

    def thread_sender
        thread = Thread.new do
            while !get_poweroff do
                begin
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
                        Logger::log_message :info, "Command sended to sched with id #{command[:update_id]}"
                        sleep 2
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_sender", e
                end
            end
        end
        thread
    end

    def thread_receiver
        thread = Thread.new do
            while !get_poweroff do
                begin
                    response = @clientSocket.read_message
                    if !response.nil?
                        response = DataUtils::eval_to_hashmap(response)
                        if response.key?(:poweroff) and response[:poweroff]
                            poweroff_updater
                            Logger::log_message :info, "Powering off updater..."
                        else
                            if response.key?(:auto)
                                Logger::log_message :info, "Received auto command with id #{response[:update_id]}"
                                chat_ids = response[:message][:chat_id]
                                chat_ids.each do |elem|
                                    make_query("#{@bot_url}/#{@bot_methods[:send_message]}", :post, {
                                        :chat_id => elem,
                                        :text => response[:response]
                                    })
                                end
                            else
                                Logger::log_message :info, "Received response from sched with id #{response[:update_id]}"
                                result = make_query("#{@bot_url}/#{@bot_methods[:send_message]}", :post, {
                                    :chat_id => response[:message][:chat_id],
                                    :text => response[:response]
                                })
                                @update_id = response[:update_id]
                            end
                            sleep 2
                        end
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_receiver", e
                end
            end
        end
        thread
    end
end