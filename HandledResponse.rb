require_relative 'ConversationState'

class HandledResponse
	attr_accessor :return_message
	attr_accessor :conversation_state

	def initialize(rm = "", cs = nil, f = true)
		self.return_message = rm
		self.conversation_state = cs
	end
end