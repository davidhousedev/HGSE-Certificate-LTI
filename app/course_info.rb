#
# Generates a URL for a specific type of API call, then calls API with that URL
#
# This API call will provide information about a specific course
# Helpful Key=>Values
# 'account_id'	=>	subaccount id
# 'start_at'	=>	start date, if available
# 'end_at'		=>	end date, if available
#
class CourseInfo < ApiController

	# allows access to course's start and end months/years by calling
	# the methods .start_month_year and .end_month_year
	attr_reader :start_month_year
	attr_reader :end_month_year
	attr_reader :subaccount

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
		
		#call api with assignment-specific URL, stores resulting hash in @api_hash
		@api_hash = super(@url)

		puts api_hash['start_at']

		# parses dates from Canvas to string with the following format: Month Year
		# Methods used:
		# => Date.parse - Parses string from Canvas to Ruby Date Object
		# => Date.strftime - Returns string of specified format according to values in Date object
		@start_month_year = Date.parse(@api_hash['start_at']).strftime('%B %Y')
		@end_month_year = Date.parse(@api_hash['end_at']).strftime('%B %Y')

		# stores Canvas account id in @subaccount variable
		@subaccount = @api_hash['account_id']
	end
end