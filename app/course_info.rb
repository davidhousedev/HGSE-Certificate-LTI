#
# Generates a URL for a specific type of API call, then calls API with that URL
#
# This API call will provide information about a specific course
#
class CourseInfo < CallApi
	def initialize(domain, course)
		#build URL
		@url = 
			"https://" + 
			"#{domain}" +
			"/api/v1/courses/" + 
			"#{course}" +
			"?access_token=" + 
			"#{TOKEN}"
		print "======= Initiated API Call ======="
		print "#{@url}"
		print "=================================="
		#call api with assignment-specific URL
		super(@url)
	end
end