class CallApi

	attr_reader :api_hash

	def initialize(api_url)
		uri = URI(api_url)
		call_api(uri)
	end


	def call_api(uri_str, limit = 10)
		raise ArgumentError, 'too many HTTP redirects' if limit == 0

		@response = Net::HTTP.get_response(URI(uri_str))

		case @response
		when Net::HTTPSuccess then
			@api_hash = JSON.parse(@response.body)
		when Net::HTTPRedirection then
			location = @response['location']
			warn "redirected to #{location}"
			call_api(location, limit - 1)
		else
			@response.value
		end
	end

	def to_s
		"#{@api_hash}"
	end
end
