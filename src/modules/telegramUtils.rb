module TelegramUtils

    #return filter a telegram message to fields that we want
    def telegram_message_to_sched(hashmap)
        time = Time.at(hashmap[:message][:date])
        message = {
            :update_id => hashmap[:update_id],
            :message   => {
                :message_id => hashmap[:message][:message_id],
                :first_name => hashmap[:message][:from][:first_name],
                :chat_id    => hashmap[:message][:chat][:id],
                :text       => hashmap[:message][:text],
                :date       => "#{time.day}/#{time.month}/#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
            }
        }
        message
    end

    def telegram_message_to_updater(hashmap)
    end

end