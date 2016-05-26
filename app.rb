
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
require './app/enrollments'
require './app/course_data'
require './app/signature_data'
require './app/template_data'



#load Canvas API token (not included in public git repo)
require './app/api_token'

#initialize file paths as constants
COURSES_PATH = "./data/courses.json"
SIGNATURES_PATH = "./data/signatures.json"
TEMPLATES_PATH = "./data/templates.json"
EVAL_METHODS_PATH = "./data/eval_methods.json"

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






  ####################
  #### LAUNCH LTI ####
  ####################

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
        custom_canvas_user_login_id
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








  ########################################
  #### STUDENT CERTIFICATE GENERATION ####
  ########################################

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

    ######## Gather student and course info from JSON files ########

    # parse courses.json to Ruby array
    @@course_data = CourseData.new
    
    # if current course is found, generate @found_hash instance variable in CourseData
    unless @@course_data.find_pair(session['context_title'], "canvas_title")
      #course is not present in json file
      return raise_error("Could not find course")
    end

    # parse signatures.json to Ruby array
    @@sig_data = SignatureData.new

    # looks for current course signature 
    # creates @found_signature instance variable in SignatureData
    index = @@course_data.json_index
    unless @@sig_data.find_pair(@@course_data.json_data[index]["signer"], "signer_name")
      # if signature for course is not found, JSON configuration is incomplete
      return raise_error("Could not find signature")
    end


    # implement completion evaluation settings
    if @@course_data.found_hash['eval_method'] = 'manual'
      unless @@course_data.is_eligible(session['custom_canvas_user_login_id'])
        return raise_error("You are not eligible to receive a certificate.")
      end
    end

    # raise error unless specified template file exists
    unless File.exist?("./public/#{@@course_data.found_hash['template']}")
      return raise_error("Certificate tmplate does not exist")
    end


    ######## Initialize variables according to specific course ########

    @full_name = session['lis_person_name_full']
    @credit_hours = @assignment_grade_results['score']

    @course_title = @@course_data.found_hash["certificate_title"]
    @course_start_date = @course_info_results.start_month_year
    @course_end_date = @course_info_results.end_month_year
    @certificate_template = @@course_data.found_hash['template']   

    @dept_head = @@course_data.found_hash["signer"]
    @dept_head_role = @@sig_data.found_hash["role"]
    @dept_head_signature = @@sig_data.found_hash["signature"]


    # render HTML document with ERB, allowing Ruby code to be 
    # evaluated <% within these tags %>
    erb :'landingpage.html'
  end









  #######################
  ####  ADMIN PANEL  ####
  #######################

  get "/admin" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end
    puts "ran get admin"

    print "== GET /admin parameters =="
    params.each { |key, value|
      print "#{key} ==> #{value}"
    }
    puts "== END =="

    # if sig added, display confirmation box
    if params['deleted']
      @sig_del = params['deleted']
      puts "/admin reports successful signature deletion"
      @sig_alert_del = "<div class=\"bs-callout bs-callout-warning\"><h4>Deleted signature: #{@sig_del}<h4></div>"
    else
      @sig_alert_del = ""
    end

    # if sig removed, display confirmation box
    if params['q'] == "sig-added"
      puts "/admin reports successful signature add"
      @sig_alert_add = "<div class=\"bs-callout bs-callout-success\"><h4>Signature Added<h4></div>"
    elsif params['q'] == "sig-exists"
      puts "/admin reports signature already added"
      @sig_alert_add = "<div class=\"bs-callout bs-callout-warning\"><h4>Signature already added<h4></div>"
    else
      @sig_alert_add = ""
    end

    @admin_course_title = session['context_title']
    @@course_found = false
    @course_message = "Course not added"

    # load json files
    @@course_data = CourseData.new
    @@sig_data = SignatureData.new
    @@template_data = TemplateData.new

    # initialize variables for dynamic HTML
    @sig_list_html = ""
    @sig_delete_list = "<option value=\"\"> Select </option>"
    @template_list = ""
    @template_delete_list = ""

    # look for current course in json data and add first option to lists
    if @@course_data.find_pair(session['context_title'], "canvas_title")
      # pull course title from JSON data
      @admin_course_title = @@course_data.found_hash["certificate_title"]
      # flag course as found in JSON data (used in POST "/admin")
      @@course_found = true

      # remmeber index for found course
      index = @@course_data.json_index

      # if signature is configured, write its value to the first option in list
      if @@sig_data.find_pair(@@course_data.json_data[index]["signer"], "signer_name")
        @found_signature = @@sig_data.found_hash['signer_name']
        @sig_list_html << ("<option value=\"" + @found_signature + "\">" + @found_signature + "</option>")
      else
        # else write a blank option to the first list
        @sig_list_html << "<option value=\"\"> Select </option>"
      end

      # if template is configured, write its value to the first option in the list
      if @@template_data.find_pair(@@course_data.json_data[index]["template"], "path")
        @found_template = @@template_data.found_hash
        @template_list << ("<option value=\"" + @found_template["path"] + "\">" + @found_template["name"] + "</option>")
        # amend delete list with blank select option, as it will not exist in @template_list
        @template_delete_list << "<option value=\"\"> Select </option>"
      else
        # else write a blank option to the first list
        @template_list << "<option value=\"\"> Select </option>"
      end

    else
      puts "@@course_found is False, course not found"
      @sig_list_html << "<option value=\"\"> Select </option>"
      @template_list << "<option value=\"\"> Select </option>"
    end

    # populates list of signatures for display, skipping currently configured signature if it exists
    @@sig_data.json_data.each { |name|
      next if @found_signature == name['signer_name']
      @sig_list_html << ("<option value=\"" + name['signer_name'] + "\">" + name['signer_name'] + "</option>")
    }
    # ammend other signature list with results from course template list
    @sig_delete_list << @sig_list_html

    # populates list of templates for display, skipping currently configured template if it exists
    @@template_data.json_data.each { |template|
      if @found_template
        next if @found_template['path'] == template['path']
      end
      @template_list << ("<option value=\"" + template["path"] + "\">" + template["name"] + "</option>")
    }
    @template_delete_list << @template_list

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
      @new_template = params['templateSelect']
      @new_method = params['evalMethod']


    if @@course_found == true
      index = @@course_data.json_index
      @@course_data.json_data[index]['certificate_title'] = @new_title
      @@course_data.json_data[index]['signer'] = @new_signer
      @@course_data.json_data[index]['template'] = @new_template
      @@course_data.json_data[index]['eval_method'] = @new_method
    else
      @@course_data.generate(session['context_title'], @new_title, @new_signer, @new_template, @new_method)
    end

    @@course_data.write_json

    print @@course_found ? "==== Modified existing course ====" : "===== Submitted new course ====="
    params.each { |key, value|
      print "#{key} ==> #{value}"
    }
    print "Submitted by #{session['lis_person_name_full']}"
    puts "============== END ============="

    @@course_found = true
    redirect to("/admin")
  end


  post "/add-sig" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    @new_sig_name = params['sigName']
    @new_sig_role = params['sigRole']
    @new_sig_img = params['sigImg']

    if !@@sig_data.find_pair(@new_sig_name, "signer_name")    

      @@sig_data.generate(@new_sig_name, @new_sig_role, @new_sig_img)
      @@sig_data.write_json

      redirect to("/admin?q=sig-added")
    else
      redirect to("/admin?q=sig-exists")    
    end
  end

  post "/remove-sig" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    @sig = params['rmSig']

    @@sig_data.find_pair(@sig, "signer_name")

    index = @@sig_data.json_index
    @@sig_data.json_data.delete_at(index)

    @@sig_data.write_json

    redirect to("/admin?deleted=#{@sig}")
  end

  post "/add-template" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    @temp_name = params['tempName']
    @temp_file = params['tempFile']

    @@template_data.generate(@temp_name, @temp_file)

    @@template_data.write_json

    redirect to ("/admin?q=template-added")
  end

  post "/remove-template" do
    @temp = params['rmTemplate']
    @@template_data.find_pair(@temp, "path")

    index = @@template_data.json_index
    @@template_data.json_data.delete_at(index)

    @@template_data.write_json

    redirect to("/admin?rmtemplate=#{@temp}")
  end











  ###########################
  #### Course Management ####
  ###########################

  get "/manage" do

    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end


    @enrollment_data = Enrollments.new(
                                        session['custom_canvas_api_domain'], 
                                        session['custom_canvas_course_id']
                                      )

    @@course_data = CourseData.new
    @@course_data.find_pair(session['context_title'], "canvas_title")
    index = @@course_data.json_index

    # gather array of login_ids already added to enrollment
    @existing_enrollments = []
    @@course_data.json_data[index]["enrollments"].each { |e|
      @existing_enrollments.push(e["login_id"])
    }


    # iterates through API data, if absent from json database adds, else skips
    @enrollment_data.enrollments_list.each { |e|

      unless @existing_enrollments.include?(e["login_id"])
        @@course_data.add_enrollment(e)
      end
    }

    @@course_data.write_json

    @enrollments = ""
    @@course_data.json_data[index]['enrollments'].each { |e|
      unless e["login_id"]
        next
      end


      checked = nil
      color = nil
      if e["eligible"] == true
        checked = "checked"
        color = "class=\"success\" "
      end

        @enrollments << (
                          "<tr #{color}><td>" + e["sortable_name"] + "</td>" + 
                              "<td>" + e["login_id"] + "</td>" + 
                              "<td>" + "<input type=\"checkbox\" name=\"" + e["login_id"] + "\" #{checked}>" + "</td></tr>"
                        )
    }

    erb :'manage.html'
  end

  post "/add-eligible" do
    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end


    index = @@course_data.json_index


    @@course_data.json_data[index]['enrollments'].each { |e|

      if params.include?(e["login_id"])
        e["eligible"] = true
      else
        e["eligible"] = false
      end
    }

    @@course_data.write_json

    redirect to("/manage")
  end

  get "/select-all" do
    # verify authenticity of session
    if invalid_session
      return "#{invalid_session}"
    end

    index = @@course_data.json_index

    @@course_data.json_data[index]['enrollments'].each { |e|
      e["eligible"] = true
    }

    @@course_data.write_json

    redirect to("/manage")
  end















  #################
  #### HELPERS ####
  #################


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
    	return raise_error("This GET does not exist")
    end


    # catch-all for all other POST requests
    post "/*" do
    	return raise_error("This POST does not exist")
    end
end
