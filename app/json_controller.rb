class JsonController
	attr_accessor :json_data
	attr_accessor :json_index
	attr_reader :found_hash

	# on init, opens json_file
	def initialize(path)
		@json_file = File.read(path)
		@json_data = JSON.parse(@json_file)
	end

	def write_json
		print "======= Writing JSON ======="
		pp @json_data

		File.open(@file_path, "w") do |f|
			f.write(JSON.pretty_generate(@json_data))
			f.close
		end
	end

	def find_pair(value, key)
		@json_data.each do |hash|
			print "comparing #{value} with #{hash[key]}"
			if hash["#{key}"] == "#{value}"
				@found_hash = hash
				@json_index = @json_data.index(hash)
				return true
			end
		end

		return false
	end

end