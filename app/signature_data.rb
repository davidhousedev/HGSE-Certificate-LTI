

class SignatureData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_signature

	def initialize
		super(SIGNATURES_PATH)
	end


	def find_signature(s_name)
		@json_data.each do |signature|
			if signature[:signer_name] == "#{s_name}"
				@found_signature = signature
				return true
			end
			
			return false
		end
	end


	def write_signature_data(arry)
		@json_data = arry
		File.open(SIGNATURES_PATH, "w") do |f|
			f.write(JSON.pretty_generate(arry))
			f.close
		end
	end
end