
#initialize libraries and gems
require "rubygems"
require "sinatra"
require "sinatra/base" 
require "tilt/erb"
require "oauth"
require 'oauth/request_proxy/rack_request'
require "net/http"
require "json"

#load class files
require './app/call_api'
require './app/assignment_grade'
#require './app/error'

#load Canvas API token (not included in public git repo)
require './app/api_token'


#still not sure what this does, but it was included in example app
# sinatra wants to set x-frame-options by default, disable it
#disable :protection

# hard-coded oauth information for testing convenience
$oauth_key = "test"
$oauth_secret = "secret"




# enable sessions so we can remember the launch info between http requests, as
# the user takes the assessment
enable :sessions



# Return string according to custom application launch error codes
# TODO: develop this into a Case statement to feed descriptive string into error view HTML
#def raise_error(1337)(code)
#  STDERR.puts("Exited with code #{code}")
#	exit(code)
#end

# This function will change all course-specific variables according to text found
# in the course title fed by Canvas.  Additional constomizations can be made by 
# adding additional "if" statements similar to the prototype example for Sandbox
# courses.  
def course_router(name)
  if name.downcase.include? "sandbox"
    @course_title = "Cindy Sandbox II"
    @dept_head = "Cindy Berhtram"
    @dept_head_role = "Senior Cat Herder"
    @dept_head_signature = "data:image/jpeg;base64,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"
  end
end 


post "/start" do
  # first we have to verify the oauth signature, to make sure this isn't an
  # attempt to hack the planet
  begin
    signature = OAuth::Signature.build(request, :consumer_secret => $oauth_secret)
    signature.verify() or raise OAuth::Unauthorized
    rescue OAuth::Signature::UnknownSignatureMethod,
           OAuth::Unauthorized
    return raise_error(1337)
  end

  # verify that user is accessing the LTI through Canvas
  unless params['resource_link_id']
    return raise_error(1337)
  end

  # verify that app was launched from a Canvas assignment
  unless params['lis_outcome_service_url']
    return raise_error(1337)
    #return "hi"
  end

  unless params['lis_outcome_service_url'] #&& params['lis_result_sourcedid']
    return %{It looks like this LTI tool wasn't launched as an assignment, or you are trying to take it as a teacher rather than as a a student. Make sure to set up an external tool assignment as outlined <a target="_blank" href="https://github.com/instructure/lti_example">in the README</a> for this example.}
  end

  # store the relevant parameters from the launch into the user's session, for
  # access during subsequent http requests.
  # note that the name and email might be blank, if the tool wasn't configured
  # in Canvas to provide that private information.
  %w(custom_canvas_api_domain resource_link_id lis_person_name_full lis_person_contact_email_primary lis_outcome_service_url context_title context_label).each { |v| session[v] = params[v] }

  # LTI is ready to launch, redirect to application
  redirect to("/cert")
end


get "/cert" do

  # verify that user is accessing the LTI through Canvas
  unless session['resource_link_id']
    return raise_error(1337)
  end

  # verify that app was launched from a Canvas assignment
  unless session['lis_outcome_service_url']
    return raise_error(1337)
  end

  ######## Initialize variables according to specific course ########
  #TODO: Find all variables that would need to alter dynamic content on PDF
  @full_name = session['lis_person_name_full']
  @credit_hours = "42" #TODO: Feed this info from Canvas

  @course_title = "default"
  @dept_head = "default"
  @dept_head_role = "default"
  @dept_head_signature = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABGdBTUEAANjr9RwUqgAAACBjSFJNAACHCAAAjBkAAPlXAACFLQAAe3EAAOugAAA/xAAAIfGatSBVAAABnmlDQ1BJQ0MgUHJvZmlsZQAAKM+t0r9Lw0AUB/BvqiJIdfEngpCpdqhSKoqKCDaDig6xCFUHJU3StFDTcLn6Y1dcBQdBHPwB4iDiJI79A6KL4FBEcHIVBBcp8S6ndFIXHxz53CPJy3s5IORpjlMIAVi1KUlNJuWFxSW5sYJ61CEITXedCVWdxY/x/gCJX+/7+LteRs9X9rNbkWGjMlS/v7yD3yNMWEFAamNus4Sj3BnhMe516lBmlVvPaQYzW4iR+ZTCvMvcYgkfcWeEr7jXdIs/W2aO20beZn5lHjZMV2f981pUdwi7J3TI3Mf7F59GZ4DxHqDOq+WWXODiDOiM1HLRLqA9DdwM1HJvc8FMpA7PzQ4kgpQUTgINT77/FgEa94Dqru9/nPh+9ZTVeATKtl4ia19zkaRb4K+96E3sxT8IhJ8s+g8iDhxPAekmYGYbOHgGei+B1mtAbQbmRyB5d99LzCqIbkUr5DNEo6Yh8+OiFAtF4jqabuJ/g5obQW9K0dkkeStH5Ql2ukxWcNUpUZPE5Glb74/JiXh8EAA+AVgGe4i47fXBAAAACXBIWXMAAAsTAAALEwEAmpwYAAAADUlEQVQYV2NgYGD4DwABBAEAcCBlCwAAAABJRU5ErkJggg=="

  # If course matches existing course, set variables and proceed
  # If not, render error message
  course_router(session['context_title'])

  #puts AssignmentGrade.new()

  # render HTML document with ERB, allowing Ruby code to be 
  # evaluated <% within these tags %>
  erb :'/index.html'
end

def raise_error(error_number)
  @error_code = error_number
  return "Error: #{@error_code}"

  #redirect to("/error")

  #get "/error" do
  #  erb :'error.html'
  #end
end





# catch-all route for all other GET requests
get "/*" do
  #puts "got a request to get'/*'"
	return raise_error(1337)
end

# catch-all for all other POST requests
post "/*" do
	return raise_error(1337)
end
