class CourseData
	attr_reader :json_data

	def initialize(path)
		@json_file = File.read(path)
		@json_data = JSON.parse(@json_file)
		return @json_data
	end

	def write_course_data(arry, path)
		File.open(path, "w") do |f|
			f.write(JSON.pretty_generate(arry))
			f.close
		end
	end

	def find_course(title)
		@json_data.each do |course|
			if course[:title] == "#{title}"
				return true
			end
		end
	end
end