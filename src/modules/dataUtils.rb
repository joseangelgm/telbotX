module DataUtils

    def eval_to_hashmap(string)
        return eval(string)
    end

    def eval_to_array(string)
        return string.split
    end

    #return filter a telegram message to fields that we want
    def filter_telegram_message(hashmap)
        message = {
            :update_id => hashmap[:update_id],
            :message   => {
                :message_id => hashmap[:message][:message_id],
                :first_name => hashmap[:message][:from][:first_name],
                :chat_id    => hashmap[:message][:chat][:id],
                :text       => hashmap[:message][:text]
            }
        }

        time = Time.at(hashmap[:message][:date])
        message[:message][:date] = "#{time.day}/#{time.month}/#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
        message
    end

end