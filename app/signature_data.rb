

class SignatureData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_signature

	def initialize
		@found_signature = nil
		super(SIGNATURES_PATH)
	end


	def find_signature(s_name)
		@json_data.each do |signature|
			puts "s_name is #{s_name} and signature[signer_name] is #{signature["signer_name"]}"
			if signature["signer_name"] == "#{s_name}"
				@found_signature = signature
				@json_index = @json_data.index(signature)
				return true
			end
		end

		return false
	end


	def write_signature_data(arry)
		@json_data = arry
		File.open(SIGNATURES_PATH, "w") do |f|
			f.write(JSON.pretty_generate(arry))
			f.close
		end
	end
end