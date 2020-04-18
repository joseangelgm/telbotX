require 'timeout'

require 'sockets/serverTCP'

require 'modules/logger'
require 'modules/dataUtils'


class Sched

    include Logger
    include DataUtils

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

    end

    def create_socket
        if @serverSocket.nil?
            @serverSocket = ServerTCP.new(@ip, @port)
            log_message :info, "Socket created", {:ip => @ip, :port => @port}
        end
    end

    def run
        begin
            log_message :info, "Waiting for Updater"
            #wait for updater to connect. It is only allow to run 1 updater at a time.
            @updater_client = @serverSocket.accept
            sock_domain, remote_port, remote_hostname, remote_ip = @updater_client.peeraddr
            log_message :info, "Updater connected", {
                :sock_domain => sock_domain,
                :remote_port => remote_port,
                :remote_hostname => remote_hostname,
                :remote_ip => remote_ip
            }

            @thread_receiver = thread_receiver
            @thread_process  = thread_process
            @thread_sender   = thread_sender

            #@thread_receiver.join
            #@thread_process.join
            @thread_sender.join

            if !@updater_client.nil? and !@updater_client.closed?
                @serverSocket.send_message @updater_client, {:poweroff => true}
            end

        rescue Errno::EBADF => exception # accept is broken because socket.close
            log_message :info, "Sched powered off with no updater"
        rescue => exception
            #log_message :info, "Exception SCHED", exception
        ensure
            @serverSocket.close
        end

        #@serverSocket.send_message @updater_client, {:poweroff => true}

        #@serverSocket.close
    end

    def poweroff_sched
        @m_poweroff.synchronize do
            @poweroff = true
        end
        if !@updater_client.nil? and !@updater_client.closed?
            @serverSocket.send_message @updater_client, {:poweroff => true}
        else
            # waiting for clients
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
                message = @serverSocket.read_message @updater_client
                command = eval_to_hashmap message
                log_message :info, "Received from updater new message", command
                update_id = command[:update_id]
                @m_commands.synchronize do
                    @commands_ids << update_id
                    @commands_info[update_id] = command
                end
            end
        end
        thread
    end

    def thread_process
        thread = Thread.new do
            while !get_poweroff
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
                    # it is a reference of the original object. But we can edit it.
                    # and will be edited the original one
                    command[:response] = "Message received #{command[:message][:command]}"
                    log_message :info, "Message processed with id #{command[:update_id]}"
                    #control if the command is poweroff!!
                    update_id = command[:update_id]
                    @m_commands_prepared.synchronize do
                        @commands_prepared << update_id
                    end
                    sleep 2
                end
            end
        end
        thread
    end

    def thread_sender
        thread = Thread.new do
            while !get_poweroff
                update_id = nil
                @m_commands_prepared.synchronize do
                    update_id = @commands_prepared.first
                end
                if !update_id.nil?
                    command = nil
                    @m_commands.synchronize do
                        command = @commands_info[update_id]
                        @commands_info.delete(update_id)
                        @commands_prepared.shift(1) if !command.nil?
                    end
                    log_message :info, "Command sended to updater", command
                    @serverSocket.send_message @updater_client, command
                end
                sleep 1
            end
        end
    end

end