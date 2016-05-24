##TODO: Mimic super/sub class structure for JSON controller
## class 3: signaturedata

class CourseData < JsonController
	# makes instance variable accessable by calling their read methods

	def initialize
		@file_path = COURSES_PATH
		super(@file_path)
	end


	def generate(canvas_title, certificate_title, signer, template, eval_method)
		buffer = {"canvas_title" => "#{canvas_title}", "certificate_title" => "#{certificate_title}", "signer" => "#{signer}", "template" => "#{template}", "eval_method" => "#{eval_method}"}
		pp buffer
		@json_data.push(buffer)
	end
end