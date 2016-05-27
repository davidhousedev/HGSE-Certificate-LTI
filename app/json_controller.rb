class JsonController
	attr_accessor :json_data
	attr_accessor :json_index
	attr_reader :found_hash
	attr_reader :html_select_list
	attr_reader :html_select_delete_list

	# on init, opens json_file
	def initialize(path)
		
		# if data directory or json file don't exist, create them
		unless Dir.exist?("./data")
			Dir.mkdir("./data")
		end

		unless File.exist?(path)
			File.open(path, "w") { |f|
				f.write("[]")
				f.close
			}
		end

		# read json file to memory and parse to Array
		@json_file = File.read(path)
		@json_data = JSON.parse(@json_file)
	end

	def write_json
		print "======= Writing JSON ======="
		pp @json_data

		File.open(@file_path, "w") do |f|
			f.write(JSON.pretty_generate(@json_data))
			f.close
		end
	end

	def find_pair(value, key)
		@json_data.each do |hash|
			print "comparing #{value} with #{hash[key]}"
			if hash["#{key}"] == "#{value}"
				@found_hash = hash
				@json_index = @json_data.index(hash)
				return true
			end
		end

		return false
	end

	def create_html_options(back_key, front_key, course = nil, course_key = nil)
		@html_select_list = ""
		@html_select_delete_list = ""

		if course
			@course_hash = course.json_data[course.json_index]

			if self.find_pair(@course_hash["#{course_key}"], back_key)
				@html_select_list << ("<option value=\"" + @found_hash["#{back_key}"] + "\">" + @found_hash["#{front_key}"] + "</option>")
				@html_select_delete_list << "<option value=\"\"> Select </option>"
			else
				@html_select_list << "<option value=\"\"> Select </option>"
			end
		else
			@html_select_list << "<option value=\"\"> Select </option>"
		end

		@json_data.each { |hash|
			if @found_hash
				if @found_hash[back_key] == hash[back_key]
					puts "skipping #{hash}"
					next
				end
			end
			puts "adding #{hash}"
			@html_select_list << ("<option value=\"" + hash[back_key] + "\">" + hash[front_key] + "</option>")
		}
		@html_select_delete_list << @html_select_list

		return true
	end

end