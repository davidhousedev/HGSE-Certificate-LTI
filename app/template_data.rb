

class TemplateData < JsonController
	# makes instance variable accessable by calling their read methods

	def initialize
		super(TEMPLATES_PATH)
	end

	def generate(template)
		buffer = {"template" => "#{template}"}
		@json_data.push(buffer)
	end

end
