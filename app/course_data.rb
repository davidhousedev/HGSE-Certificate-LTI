##TODO: Mimic super/sub class structure for JSON controller
## class 3: signaturedata

class CourseData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_course

	def initialize
		super(COURSES_PATH)
	end


	def find_course(canvas_title)
		@json_data.each do |course|
			if course[:canvas_title] == "#{canvas_title}"
				@found_course = course
				return true
			else
				return false
			end
		end
	end


	def write_course_data(arry)
		@json_data = arry
		File.open(COURSES_PATH, "w") do |f|
			f.write(JSON.pretty_generate(arry))
			f.close
		end
	end
end