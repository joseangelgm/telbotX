=begin
Access:
    File::RDONLY -> Read-Only
    File::WRONLY -> Write-only
    File::RDWR   -> Read and write

If the file doesnt exists:
    File::TRUNC  -> Truncate
    File::APPEND -> Append
    File::EXCL   -> Fail

If the file doesn’t exist:
    File::CREAT -> Create
=end

#f1.flock(File::LOCK_EX|File::LOCK_NB) -> to not block when the lock is taken

module Logger

    extend self

    MAX_SIZE = 1024000 #Kilobytes
    LOG_FILE = "/tmp/telbotX.log"
    TIME_FORMAT = "%d/%m/%Y %H:%M:%S"

    def log_message(mode, title, message=nil)
        begin
            f = File.open(LOG_FILE, File::RDWR|File::APPEND|File::CREAT, 0644)
            f.flock(File::LOCK_EX)

            message_hash = {
                :time          => Time.now.strftime(TIME_FORMAT),
                :caller_object => caller.first.scan(/\/\w+/).last.tr('/',''),
                :mode          => mode,
                :title         => title,
                :message       => format_message(message)
            }
            message_format = "%{time} %{caller_object} %{mode}: %{title}\n%{message}" % message_hash
            f.write(message_format)
        rescue Exception => e
            #format_message(e)
        ensure
            if !f.nil?
                f.flock(File::LOCK_UN)
                f.close
            end
        end
    end

    def create_log_file_if_necessary
        if File.file?(LOG_FILE)
            current_time = Time.new
            stats = File.stat(LOG_FILE)
            if stats.size >= MAX_SIZE || (stats.ctime.day != current_time.day)
                File.rename(LOG_FILE, "#{LOG_FILE}.#{current_time.year}-#{current_time.month}-#{current_time.day}")
            end
        end
    end

    def format_message(message)

        message_formatted = ""

        case message
        when Hash;
            message.each do |k, v|
                message_formatted << "\t" << k.to_s.ljust(15) << " -> " << v.to_s << "\n"
            end
        when Array;
            message.each do |elem|
                message_formatted << "\t#{elem}\n"
            end
        when Exception;
            message_formatted = "\tException type: #{message.class} => #{message.message}\n"
        when nil;
            message_formatted = ""
        else;
            message_formatted = "#{message}\n"
        end
        message_formatted
    end

    private :format_message
end