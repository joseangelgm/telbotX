module DataUtils

    def eval_to_hashmap(string)
        hash = nil
        begin
            hash = eval(string)
        rescue => exception
        end
        hash
    end

    def eval_to_array(string)
        return string.split
    end
end