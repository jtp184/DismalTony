class ConversationState
	attr_accessor :depth
	attr_accessor :queries
	attr_accessor :memory
	attr_accessor :is_finished

	def finished?
		return self.is_finished
	end

	
end