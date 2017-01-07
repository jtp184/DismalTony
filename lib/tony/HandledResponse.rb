module Tony
class HandledResponse
	attr_accessor :return_message
	attr_accessor :conversation_state

	def initialize(rm = "", cs = nil, f = true)
		@return_message = rm
		@conversation_state = cs
	end

	def to_s
		return @return_message
	end
end
end