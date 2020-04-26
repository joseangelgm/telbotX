require 'modules/logger'
require 'modules/fileUtils'
include FileUtils

class AdminsManager

    include Logger

    def initialize
        # user -> chat_id
        @admins = {}
        @admins_users = FileUtils::load_from_file("#{__dir__}/../config/admins.yaml")
        @admins_m = Mutex.new
    end

    def create_or_update_info(user, chat_id)
        @admins_m.synchronize do
            if @admins_users.include? user
                @admins[user.to_sym] = chat_id
                log_message :info, "Admin registered with name #{user} and chat_id #{chat_id}"
            end
        end
    end

    def get_all_chats_ids()
        chat_ids = []
        @admins_m.synchronize do
            @admins.each do |k, v|
                chat_ids << v
            end
        end
        chat_ids
    end
end