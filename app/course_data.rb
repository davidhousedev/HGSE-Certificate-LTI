##TODO: Mimic super/sub class structure for JSON controller
## class 3: signaturedata

class CourseData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_course

	def initialize
		@file_path = COURSES_PATH
		super(@file_path)
	end


	def find_course(canvas_title)
		@json_data.each do |course|
			print "Comparing #{course['canvas_title']} with #{canvas_title}"
			if course["canvas_title"] === "#{canvas_title}"
				@found_course = course
				@json_index = @json_data.index(course)
				return true
			end
		end
		return false
	end

	def generate(canvas_title, certificate_title, signer, template, eval_method)
		buffer = {"canvas_title" => "#{canvas_title}", "certificate_title" => "#{certificate_title}", "signer" => "#{signer}", "template" => "#{template}", "eval_method" => "#{eval_method}"}
		pp buffer
		@json_data.push(buffer)
	end
end