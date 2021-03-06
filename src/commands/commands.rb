require 'modules/logger'
include Logger

class Commands

    def initialize()
        @path = "#{__dir__}/executables/"
    end

    # telbotx format
    # this method will create the response within hashmap command. Change that.w
    def execute_command(command)
        path_exe = "#{@path}#{command[:message][:command]}"
        Logger::log_message :info, "Executing command #{command[:update_id]}", {
            :update_id => command[:update_id],
            :path => path_exe,
            :command => command[:message][:command],
            :args => command[:message][:args]
        }
        if File.file? path_exe
            if !command[:message][:args].nil?
                path_exe << " #{command[:message][:args]}"
                path_exe.gsub!(/\s$/, '')# remove blank spaces if we dont have any argument
            end
            output = %x("#{path_exe}")
            if $?.exitstatus != 0
                output = "There was a problem executing the command with id #{command[:update_id]}"
            end
            if command.key?(:auto)
                command[:response] = "Auto: #{output}"
            else
                command[:response] = output
            end
        else
            Logger::log_message :info, "Command #{command[:update_id]} doesn't exists"
            command[:response] = "The command #{command[:message][:command]} doesn't exists"
        end
        Logger::log_message :info, "Response for #{command[:update_id]}: #{command[:response]}"
    end
end