class JsonController
	attr_accessor :json_data
	attr_accessor :json_index

	# on init, opens json_file
	def initialize(path)
		@json_file = File.read(path)
		@json_data = JSON.parse(@json_file)
	end

end