##TODO: Mimic super/sub class structure for JSON controller
## class 3: signaturedata

class CourseData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_course

	def initialize
		super(COURSES_PATH)
	end


	def find_course(canvas_title)
		puts @json_data.class
		@json_data.each do |course|
			if course["canvas_title"] == "#{canvas_title}"
				@found_course = course
				@json_index = @json_data.index(course)
				return true
			end
			
			return false
		end
	end


	def write_course_data
#		if @found_course == nil
#			puts "ERROR: Attempted to save changes to course before finding it"
#			return false
#		end

		File.open(COURSES_PATH, "w") do |f|
			f.write(JSON.pretty_generate(@json_data))
			f.close
		end
	end
end