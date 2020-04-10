#because is launched from updaterLauncher.rb the paths are like following.
require 'sockets/clientTCP'

require 'modules/logger'
require 'modules/queryHTTP'
require 'modules/dataUtils'

class Updater

    include Logger
    include QueryHTTP
    include DataUtils

    GET_UPDATES = "getUpdates"
    private_constant :GET_UPDATES

    attr_reader :update_id

    public

    def initialize(bot_url, ip, port, update_id)
        @bot_url  = "#{bot_url}/#{GET_UPDATES}"

        @ip   = ip
        @port = port

    end
end