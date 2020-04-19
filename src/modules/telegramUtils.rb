module TelegramUtils

    extend self

    #parse telegram format of a message to telbotx format
    def update_to_command(command_to_parse)

        time = Time.at(command_to_parse[:message][:date])
        array_command = command_to_parse[:message][:text].split(" ")

        command = {
            :update_id => command_to_parse[:update_id],
            :message => {
                :username => command_to_parse[:message][:chat][:username],
                :chat_id  => command_to_parse[:message][:chat][:id],
                :message_id => command_to_parse[:message][:message_id],
                :command => array_command[0].tr('/',''),
                :args => array_command[1..].join(" ")
            },
            :date => "#{time.day}/#{time.month}/#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
        }
        command
    end
end