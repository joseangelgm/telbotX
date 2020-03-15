#because is launched from telbotx.rb.
require 'sockets/clientTCP'
require 'modules/logger'

class Updater

    include Logger

    GET_UPDATES = "getUpdates"

    def initialize(bot_url)
        @bot_url = bot_url
    end

end