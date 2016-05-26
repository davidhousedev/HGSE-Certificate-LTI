

class TemplateData < JsonController
	# makes instance variable accessable by calling their read methods

	def initialize
		@file_path = TEMPLATES_PATH
		super(@file_path)
	end

	def generate(template_name, file_name)
		buffer = {"name" => "#{template_name}", "path" => "#{file_name}"}
		@json_data.push(buffer)
	end

end
