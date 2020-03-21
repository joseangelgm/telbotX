require 'yaml'

module FileUtils

    # no thread safe
    # load the content of -path_file-
    def load_from_file(path_file)
        config_file = nil
        if File.file?(path_file)
            case File.extname(path_file)[1..] # get the ext of file removing the dot
            when "yaml", "yml"
                config_file = YAML::load_file(path_file)
            end
        end
        config_file
    end

    # no thread safe
    # save -info- into -path_file
    def save_into_file(path_file, info)
        if File.file?(path_file)
            case File.extname(path_file)[1..] # get the ext of file removing the dot
            when "yaml", "yml"
                File.open(path_file, 'w') do |f|
                    f.write info.to_yaml
                end
            end
        end
    end
end