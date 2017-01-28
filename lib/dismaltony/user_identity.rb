module DismalTony
	class UserIdentity
		attr_accessor :user_data
		attr_accessor :conversation_state

		def self.default_user
			ident = DismalTony::UserIdentity.new
			ident['nickname'] = 'User'
			ident['first_name'] = 'Default'
			ident['last_name'] = 'User'
			return ident
		end

		def state
			@conversation_state
		end

		def initialize()
			@user_data = {}
			@conversation_state = DismalTony::ConversationState.new(:is_idle => true, :the_user => self)
		end

		def[]=(left, right)
			@user_data[left] = right
		end

		def[](str)
			@user_data[str]
		end

		def modify_state(new_state)
			@conversation_state.from_h! new_state.to_h
		end
	end
end