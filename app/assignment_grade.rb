#
# Generates a URL for a specific type of API call, then calls API with that URL
#
# This API call will provide information about a specific grade event for a specified
# student, in a specified course.
#
class AssignmentGrade < CallApi
	def initialize(domain, course, assignment, student)
		#build URL
		@url = 
			"https://" + 
			domain +
			"/api/v1/courses/" + 
			"#{course}" +
			"/assignments/" + 
			"#{assignment}" + 
			"/submissions/" + 
			"#{student}" + 
			"?access_token=" + 
			TOKEN
		#call api with assignment-specific URL
		super(@url)
	end
end