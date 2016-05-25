class Enrollments < ApiController

	# allows access to course's start and end months/years by calling
	# the methods .start_month_year and .end_month_year

	attr_reader :enrollments_list

	def initialize(domain, course)
		#build URL
		@url = 
			"https://" + 
			"#{domain}" +
			"/api/v1/courses/" + 
			"#{course}" +
			"/enrollments" + 
			"?access_token=" + 
			"#{TOKEN}"
		print "======= Initiated API Call ======="
		print "#{@url}"
		print "=================================="
		
		#call api with assignment-specific URL, stores resulting hash in @api_hash
		@api_hash = super(@url)

		@enrollments_list = []
		@api_hash.each { |v|
			if v["role"] == "StudentEnrollment"
				@enrollments_list.push(v["user"])
			end
		}


	end
end