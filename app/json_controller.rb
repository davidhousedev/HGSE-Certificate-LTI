class JsonController
	attr_reader :json_data

	# on init, opens json_file
	def initialize(path)
		@json_file = File.read(path)
		@json_data = JSON.parse(@json_file)
	end

end