require 'net/http'
require 'uri'
require 'json'

module QueryHTTP

    extend self

    def make_query(url, http_method, params)
		res = nil
        if http_method == :get then
        	uri = URI(url)
          	uri.query = URI.encode_www_form(params)
          	res = Net::HTTP.get_response(uri)
        elsif http_method == :post then
            uri = URI.parse(url)
            res = Net::HTTP.post_form(uri, params)
        end
        if !res.nil?
            code = res.code
            response = JSON.parse(res.body) if res != nil
            response = symbolize_recursive(response)

            return {
                :status => code,
                :body 	=> response
            }
        else
            return nil
        end
    end

    def symbolize_recursive(hash)
    	{}.tap do |h|
        	hash.each {|key, value| h[key.to_sym] = transform(value)}
        end
    end

    def transform(elem)
    	case elem
        when Hash; symbolize_recursive(elem)
        when Array; elem.map {|v| transform(v)}
        else; elem
        end
	end

	private :symbolize_recursive
	private :transform

end