require 'securerandom'

require 'sockets/serverTCP'
require 'commands/commands'
require 'pieces/adminsManager'

require 'modules/logger'
require 'modules/dataUtils'
require 'modules/telegramUtils'
require 'modules/fileUtils'

include DataUtils
include TelegramUtils
include Logger

class Sched

    public

    def initialize(ip, port)
        @ip     = ip
        @port   = port
        @serverSocket = nil
        @updater_client = nil

        @command_id = nil

        @poweroff = false
        @m_poweroff = Mutex.new

        @commands_ids  = []
        @commands_info = {}
        @m_commands = Mutex.new

        @commands_prepared = []
        @m_commands_prepared = Mutex.new

        @thread_receiver = nil
        @thread_process  = nil
        @thread_sender   = nil

        @command_exe = Commands.new
        @admins = AdminsManager.new

    end

    def create_socket
        if @serverSocket.nil?
            @serverSocket = ServerTCP.new(@ip, @port)
            Logger::log_message :info, "Socket created", {:ip => @ip, :port => @port}
        end
    end

    def run
        begin
            Logger::log_message :info, "Waiting for Updater"
            #wait for updater to connect. It is only allow to run 1 updater at a time.
            @updater_client = @serverSocket.accept
            sock_domain, remote_port, remote_hostname, remote_ip = @updater_client.peeraddr
            Logger::log_message :info, "Updater connected", {
                :sock_domain => sock_domain,
                :remote_port => remote_port,
                :remote_hostname => remote_hostname,
                :remote_ip => remote_ip
            }

            @thread_receiver = thread_receiver
            @thread_process  = thread_process
            @thread_sender   = thread_sender

            @thread_receiver.report_on_exception = false
            @thread_process.report_on_exception  = false
            @thread_sender.report_on_exception   = false

            threads_auto_commands = []

            auto_commands = FileUtils::load_from_file("#{__dir__}/../commands/commands.yaml")
            Logger::log_message :debug, "Auto commands", auto_commands
            auto_commands.each do |command, attrs|
                thread = thread_automatically(command, attrs)
                thread.report_on_exception = false
                threads_auto_commands << thread
            end

            #@thread_receiver.join
            #@thread_process.join
            @thread_sender.join

            if !@updater_client.nil? and !@updater_client.closed?
                @serverSocket.send_message @updater_client, {:poweroff => true}
            end

        rescue Errno::EBADF => exception # accept is broken because of socket.close
            Logger::log_message :info, "Sched powered off with no updater", exception
        rescue Exception => e
            Logger::log_message :info, "Exception powering off sched", e
        ensure
            @serverSocket.close
        end
    end

    def poweroff_sched
        @m_poweroff.synchronize do
            @poweroff = true
        end
        if !@updater_client.nil? and !@updater_client.closed?
            @serverSocket.send_message @updater_client, {:poweroff => true}
        else
            @serverSocket.close
        end

    end

    private

    def get_poweroff
        poweroff = false
        @m_poweroff.synchronize do
            poweroff = @poweroff
        end
        poweroff
    end

    def thread_receiver
        thread = Thread.new do
            while !get_poweroff
                begin
                    message = @serverSocket.read_message @updater_client
                    command = DataUtils::eval_to_hashmap message
                    @admins.create_or_update_info(command[:message][:username], command[:message][:chat_id])
                    update_id = command[:update_id]
                    Logger::log_message :info, "Received from updater new message with id #{update_id}"
                    @m_commands.synchronize do
                        @commands_ids << update_id
                        @commands_info[update_id] = command
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_receiver", e
                end
            end
        end
        thread
    end

    def thread_process
        thread = Thread.new do
            while !get_poweroff
                begin
                    command = nil
                    @m_commands.synchronize do
                        update_id = @commands_ids.first
                        if !update_id.nil?
                            command = @commands_info[update_id]
                            @commands_ids.shift(1) if !command.nil?
                        end
                    end
                    if !command.nil?
                        # execute command[:message][:command]
                        # it is a reference of the original object. But we can edit it
                        # and will be edited the original because we are editing a nested
                        # hashmap. Should be cloned.
                        @command_exe.execute_command(command)
                        #control if the command is poweroff!!
                        update_id = command[:update_id]
                        @m_commands_prepared.synchronize do
                            @commands_prepared << update_id
                        end
                        sleep 2
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_process", e
                end
            end
        end
        thread
    end

    def thread_sender
        thread = Thread.new do
            while !get_poweroff
                begin
                    update_id = nil
                    @m_commands_prepared.synchronize do
                        update_id = @commands_prepared.first
                        @commands_prepared.shift(1) if !update_id.nil?
                    end
                    if !update_id.nil?
                        command = nil
                        @m_commands.synchronize do
                            command = @commands_info.delete(update_id)
                        end
                        if !command.nil?
                            @m_commands_prepared.synchronize do
                                @commands_prepared.shift(1)
                            end
                            @serverSocket.send_message @updater_client, command
                            Logger::log_message :info, "Command sended to updater with id #{update_id}"
                        end
                        sleep 2
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_sender", e
                end
            end
        end
        thread
    end

    def thread_automatically(command, attrs)
        thread = Thread.new do
            command_struct = TelegramUtils::build_telbotx_auto_command(command, attrs)
            while !get_poweroff
                begin
                    ids = @admins.get_all_chats_ids
                    if !ids.nil? && !ids.empty?
                        command_struct[:update_id] = SecureRandom.uuid
                        command_struct[:message][:chat_id] = @admins.get_all_chats_ids
                        @command_exe.execute_command(command_struct)
                        update_id = command_struct[:update_id]
                        @m_commands.synchronize do
                            @commands_info[update_id] = command_struct
                        end
                        @m_commands_prepared.synchronize do
                            @commands_prepared << update_id
                        end
                        Logger::log_message :info, "Create auto command with id #{update_id}", command_struct
                        sleep attrs[:interval]
                    end
                rescue Exception => e
                    Logger::log_message :info, "Exception thread_automatically", e
                end
            end
        end
        thread
    end
end