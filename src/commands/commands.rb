require 'modules/logger'

class Commands

    include Logger

    def initialize()
        @path = "#{__dir__}/executables/"
    end

    # telbotx format
    # this method will create the response within hashmap command. Change that.w
    def execute_command(command)
        path_exe = "#{@path}#{command[:message][:command]}"
        log_message :info, "Executing command #{command[:update_id]}", {
            :update_id => command[:update_id],
            :path => path_exe,
            :command => command[:message][:command],
            :args => command[:message][:args]
        }
        if File.file? path_exe
            path_exe << " #{command[:message][:args]}".gsub!(/\s$/, '') # remove blank spaces if we dont have any argument
            output = %x("#{path_exe}")
            if $?.exitstatus != 0
                output = "There was a problem executing the command with id #{command[:update_id]}"
            end
            command[:response] = output
        else
            log_message :info, "Command #{command[:update_id]} doesn't exists"
            command[:response] = "The command #{command[:message][:command]} doesn't exists"
        end
        log_message :info, "Response for #{command[:update_id]}: #{command[:response]}"
    end
end