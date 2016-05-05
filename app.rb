
#initialize RubyGems
require "rubygems"
require "sinatra" 
require "oauth"
require 'oauth/request_proxy/rack_request'

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
def canvas_launch_error(code)
	return ("Error #{code.to_s}")
end

post "/start" do
  # first we have to verify the oauth signature, to make sure this isn't an
  # attempt to hack the planet
  begin
    signature = OAuth::Signature.build(request, :consumer_secret => $oauth_secret)
    signature.verify() or raise OAuth::Unauthorized
  rescue OAuth::Signature::UnknownSignatureMethod,
         OAuth::Unauthorized
    canvas_launch_error(4)
  end

  # verify that user is accessing the LTI through Canvas
  unless params['resource_link_id']
    canvas_launch_error(5)
  end

  # store the relevant parameters from the launch into the user's session, for
  # access during subsequent http requests.
  # note that the name and email might be blank, if the tool wasn't configured
  # in Canvas to provide that private information.
  %w( resource_link_id lis_person_name_full lis_person_contact_email_primary context_title context_label).each { |v| session[v] = params[v] }

  # LTI is ready to launch, redirect to application
  redirect to("/cert")
end

get "/cert" do

  # verify that user is accessing the LTI through Canvas
  unless session['resource_link_id']
    return canvas_launch_error(3)
  end

  ######## Initialize variables according to specific course ########
  #TODO: Find all variables that would need to alter dynamic content on PDF
  @full_name = session['lis_person_name_full']
  @credit_hours = "42" #TODO: Feed this info from Canvas

  @course_title = "default"
  @dept_head_signature = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABGdBTUEAANjr9RwUqgAAACBjSFJNAACHCAAAjBkAAPlXAACFLQAAe3EAAOugAAA/xAAAIfGatSBVAAABnmlDQ1BJQ0MgUHJvZmlsZQAAKM+t0r9Lw0AUB/BvqiJIdfEngpCpdqhSKoqKCDaDig6xCFUHJU3StFDTcLn6Y1dcBQdBHPwB4iDiJI79A6KL4FBEcHIVBBcp8S6ndFIXHxz53CPJy3s5IORpjlMIAVi1KUlNJuWFxSW5sYJ61CEITXedCVWdxY/x/gCJX+/7+LteRs9X9rNbkWGjMlS/v7yD3yNMWEFAamNus4Sj3BnhMe516lBmlVvPaQYzW4iR+ZTCvMvcYgkfcWeEr7jXdIs/W2aO20beZn5lHjZMV2f981pUdwi7J3TI3Mf7F59GZ4DxHqDOq+WWXODiDOiM1HLRLqA9DdwM1HJvc8FMpA7PzQ4kgpQUTgINT77/FgEa94Dqru9/nPh+9ZTVeATKtl4ia19zkaRb4K+96E3sxT8IhJ8s+g8iDhxPAekmYGYbOHgGei+B1mtAbQbmRyB5d99LzCqIbkUr5DNEo6Yh8+OiFAtF4jqabuJ/g5obQW9K0dkkeStH5Ql2ukxWcNUpUZPE5Glb74/JiXh8EAA+AVgGe4i47fXBAAAACXBIWXMAAAsTAAALEwEAmpwYAAAADUlEQVQYV2NgYGD4DwABBAEAcCBlCwAAAABJRU5ErkJggg=="

  #TODO: Implement a prototype course for setting course-specific variables
  def cindy_sandbox_II
    #@course_title = "Cindy Sandbox II"
    #@dept_head_signature = TODO: add data URL for prototype signature
  end



  # render HTML document with ERB, allowing Ruby code to be 
  # evaluated <% within these tags %>
	erb :'index.html'
end

# catch-all route for all other GET requests
get "/*" do
	canvas_launch_error(1)
end

# catch-all for all other POST requests
post "/*" do
	canvas_launch_error(2)
end