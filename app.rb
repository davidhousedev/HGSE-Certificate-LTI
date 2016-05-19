
#initialize libraries and gems
require "rubygems"
require "sinatra"
require "sinatra/base" 
require "tilt/erb"
require "oauth"
require 'oauth/request_proxy/rack_request'
require "net/http"
require "json"
require "pp"
require 'date'

#load class files
require './app/api_controller'
require './app/json_controller'
require './app/assignment_grade'
require './app/course_info'
require './app/course_data'
require './app/signature_data'


#load Canvas API token (not included in public git repo)
require './app/api_token'

#initialize file paths as constants
COURSES_PATH = "./data/courses.json"
SIGNATURES_PATH = "./data/signatures.json"

#TODO: implement file lock on JSON file access to prevent overwrites of temp data

#still not sure what this does, but it was included in example app
# sinatra wants to set x-frame-options by default, disable it
#disable :protection

# hard-coded oauth information for testing convenience
$oauth_key = "test"
$oauth_secret = "secret"


class LtiApp < Sinatra::Base

  # enable sessions so we can remember the launch info between http requests, as
  # the user takes the assessment
  enable :sessions

  #alternate session setup
  #use Rack::Session::Pool, :expire_after => 2592000


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
    end


    # store the relevant parameters from the launch into the user's session, for
    # access during subsequent http requests.
    # note that the name and email might be blank, if the tool wasn't configured
    # in Canvas to provide that private information.
      %w( 
        roles 
        custom_canvas_api_domain 
        resource_link_id 
        lis_person_name_full 
        lis_person_contact_email_primary 
        lis_outcome_service_url 
        context_title 
        custom_canvas_course_id
        custom_canvas_assignment_id
        custom_canvas_user_id
        ).each { |v| session[v] = params[v] }

        #Log Access Request
        puts
        puts "====== Server accessed: ======="
        params.each {|key, value| 
            print "#{key} => #{value}"
        }
        puts
        puts


    if session['roles'].include?("urn:lti:instrole:ims/lis/Administrator")
      redirect to("/admin")
    elsif session['roles'].include?("Instructor")
      redirect to("/manage")
    elsif session['roles'].include?("TeachingAssistant")
      redirect to("/manage")
    elsif session['roles'].include?("ContentDeveloper")
      redirect to("/manage")
    else
      redirect to("/cert")
    end

  end




  get "/cert" do


    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    # get API data on current assignment
    @assignment_grade_results = AssignmentGrade.new(
                                                    session['custom_canvas_api_domain'], 
                                                    session['custom_canvas_course_id'], 
                                                    session['custom_canvas_assignment_id'], 
                                                    session['custom_canvas_user_id']
                                                    ).api_hash

    # get API data on current course
    @course_info_results = CourseInfo.new(
                                          session['custom_canvas_api_domain'], 
                                          session['custom_canvas_course_id'])


    # parse courses.json to Ruby array
    @@course_data = CourseData.new
    
    # if current course is found, generate @found_course instance variable in CourseData
    unless @@course_data.find_course(session['context_title'])
      #course is not present in json file
      return raise_error("Could not find course")
    end

    # parse signatures.json to Ruby array
    @@sig_data = SignatureData.new

    # looks for current course signature 
    # creates @found_signature instance variable in SignatureData
    index = @@course_data.json_index
    unless @@sig_data.find_signature(@@course_data.json_data[index]["signer"])
      # if signature for course is not found, JSON configuration is incomplete
      return raise_error("Could not find signature")
    end


    ######## Initialize variables according to specific course ########

    @full_name = session['lis_person_name_full']
    @credit_hours = @assignment_grade_results['grade']

    @course_title = @@course_data.found_course["certificate_title"]
    @course_start_date = @course_info_results.start_month_year
    @course_end_date = @course_info_results.end_month_year

    @dept_head = @@course_data.found_course["signer"]
    @dept_head_role = @@sig_data.found_signature["role"]
    @dept_head_signature = @@sig_data.found_signature["signature"]


    # render HTML document with ERB, allowing Ruby code to be 
    # evaluated <% within these tags %>
    erb :'index.html'
  end

  get "/manage" do 
    
    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    "Welcome to course admin"
  end

  get "/admin" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end
    puts "ran get admin"

    @admin_course_title = session['context_title']
    @@course_found = false
    @course_message = "Course not added"

    # load json files
    @@course_data = CourseData.new
    @@sig_data = SignatureData.new

    # initialize variables for dynamic HTML
    @sig_list_html = ""

    # look for current course in json data
    if @@course_data.find_course(session['context_title'])
      @admin_course_title = @@course_data.found_course["certificate_title"]
      @@course_found = true
      puts "@@course_found set to True"
      @course_message = "Course FOUND. Submit this form to change information."

      index = @@course_data.json_index
      if @@sig_data.find_signature(@@course_data.json_data[index]["signer"])
        @found_signature = @@sig_data.found_signature['signer_name']
        @sig_list_html << ("<option value=\"" + @found_signature + "\">" + @found_signature + "</option>")
      else
        @sig_list_html << ("<option value=\"\"> Select </option>")
      end
    else
      puts "@@course_found is False, course not found"
      @sig_list_html << ("<option value=\"\"> Select </option>")
    end

   
    @@sig_data.json_data.each { |name|
      next if @found_signature == name['signer_name']
      @sig_list_html << ("<option value=\"" + name['signer_name'] + "\">" + name['signer_name'] + "</option>")
      puts @sig_list_html
    }

    erb :'admin.html'
  end

  post "/admin" do
    

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    pp params

    @new_title = params['courseName']
    @new_signer = params['sigSelect']


    if @@course_found == true
      puts "Executing course found"
      index = @@course_data.json_index
      @@course_data.json_data[index]['certificate_title'] = @new_title
      @@course_data.json_data[index]['signer'] = @new_signer
    else
      @@course_data.generate(session['context_title'], @new_title, @new_signer)
    end


    @@course_data.write_course_data

    @sig_list_html = ""
    @sig_list_html << ("<option value=\"" + @new_signer + "\">" + @new_signer + "</option>")
    @@sig_data.json_data.each { |name|
      next if @new_signer == name['signer_name']
      @sig_list_html << ("<option value=\"" + name['signer_name'] + "\">" + name['signer_name'] + "</option>")
      puts @sig_list_html
    }


    print @@course_found ? "==== Modified existing course ====" : "===== Submitted new course ====="
    params.each { |key, value|
      print "#{key} ==> #{value}"
    }
    print "Submitted by #{session['lis_person_name_full']}"
    puts "============== END ============="

    @@course_found = true
    erb :'admin.html'
  end



  def raise_error(error_number)
    @error_code = error_number
    return "Error: #{@error_code}"

    #redirect to("/error")

    #get "/error" do
    #  erb :'error.html'
    #end
  end

  def invalid_session
    # verify that user is accessing the LTI through Canvas
    unless session['resource_link_id']
      return raise_error(1337)
    end

    # verify that app was launched from a Canvas assignment
    unless session['lis_outcome_service_url']
      return raise_error(1337)
    end

    return false
  end



  # catch-all routes
    # catch-all route for all other GET requests
    get "/*" do
    #  #puts "got a request to get'/*'"
    	return raise_error(1337)
    end


    # catch-all for all other POST requests
    post "/*" do
    	return raise_error(1337)
    end
end
