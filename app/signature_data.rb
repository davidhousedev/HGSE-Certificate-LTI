

class SignatureData < JsonController
	# makes instance variable accessable by calling their read methods
	attr_reader :found_hash

	def initialize
		@found_hash = nil
		@file_path = SIGNATURES_PATH
		super(@file_path)
	end

	def generate(signer_name, role, signature)
		buffer = {"signer_name" => "#{signer_name}", "role" => "#{role}", "signature" => "#{signature}"}
		@json_data.push(buffer)
	end


end
