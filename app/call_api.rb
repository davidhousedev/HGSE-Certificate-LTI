#
# Facilitates communication with Canvas API server
# Retrieves JSON data, parses it, and makes available
# via the @api_hash attribute.
#
class CallApi

	# allows retrieval of @api_hash by calling .api_hash
	attr_reader :api_hash

	# converts input URL from sub class to URI, then calls API server
	def initialize(api_url)
		uri = URI(api_url)
		call_api(uri)
	end

	# facilitates moving through redirects until success
	def call_api(uri_str, limit = 10)
		# if 10 redirects, end process with error
		raise ArgumentError, 'too many HTTP redirects' if limit == 0

		# sends initial request to Canvas server
		@response = Net::HTTP.get_response(URI(uri_str))

		# if success, log results to server and to @api_hash variable
		case @response
		when Net::HTTPSuccess then
			# store Ruby hash results from JSON parse
			@api_hash = JSON.parse(@response.body)
			# record results to server logs
			@api_hash.each { |key, value|
				print "#{key} ==> #{value}"
			}
			puts "=====Success====="
		# if redirect, proceed until success
		when Net::HTTPRedirection then
			location = @response['location']
			warn "redirected to #{location}"
			call_api(location, limit - 1)
		else
			@response.value
		end

		return @api_hash
	end

	def to_s
		"#{@api_hash}"
	end
end
