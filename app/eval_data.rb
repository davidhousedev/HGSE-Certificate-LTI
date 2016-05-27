

class EvalData < JsonController
	# makes instance variable accessable by calling their read methods

	def initialize
		@found_hash = nil
		@file_path = EVAL_METHODS_PATH
		super(@file_path)
	end

	def generate(eval_name, method_name)
		buffer = {"name" => "#{eval_name}", "method" => "#{method_name}"}
		@json_data.push(buffer)

		puts "WRITING EVAL DATA", buffer, @json_data
	end


end
