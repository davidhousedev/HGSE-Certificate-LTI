

class EvaluationData < JsonController

	def initialize
		super(EVAL_METHODS_PATH)
	end

	def generate(method)
		buffer = {"method" => "#{method}"}
		@json_data.push(buffer)
	end

end
