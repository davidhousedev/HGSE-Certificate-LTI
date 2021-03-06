##TODO: Mimic super/sub class structure for JSON controller
## class 3: signaturedata

class CourseData < JsonController
	# makes instance variable accessable by calling their read methods

	def initialize
		@file_path = COURSES_PATH
		super(@file_path)
	end


	def generate(canvas_title, certificate_title, signer, template, eval_method)
		buffer = {
				"canvas_title" => "#{canvas_title}", 
				"certificate_title" => "#{certificate_title}", 
				"signer" => "#{signer}", 
				"template" => "#{template}", 
				"eval_method" => "#{eval_method}",
				"enrollments" => []
				}
		pp buffer
		@json_data.push(buffer)
	end

	# adds single enrollment hash to course
	def add_enrollment(enrollment)
		unless @found_hash
			return false
		end

		@json_data[@json_index]["enrollments"].push(enrollment)

		puts @found_hash
		return true
	end

	# determines elegibility of student to receive certificate
	def is_eligible(login_id)

		@found_hash["enrollments"].each { |e|
			if e["login_id"] == login_id && e["eligible"] == true
				print "#{e["login_id"]} == #{login_id}"
				print "#{e["eligible"]} == true"
				puts "#{login_id} is eligible for a certificate"
				return true
			end
		}
		puts "#{login_id} is not eligible for a certificate."
		return false
	end
end