module DismalTony # :nodoc:
  # Represents the identity of the user submitting queries. Used both to allow for stated conversation,
  # and as a way to keep user-specific information isolated from other user-specific information, such as
  # names, phone numbers, preferences, etc.
  class UserIdentity
    # A Hash. +user_data+ keeps track of unique information. Calling <tt>UserIdentity[key]</tt> retrieves from here.
    attr_reader :user_data
    # A ConversationState object corresponding to this user's conversation state.
    attr_reader :conversation_state

    # Options for +args+:
    #
    # * +:user_data+ - The hash to use. Defaults to an Empty hash.
    # * +:conversation_state+ - The ConversationState to use. Defaults to a blank, idle state.
    def initialize(**args)
      @user_data = (args[:user_data] || {})
      @conversation_state = (args[:conversation_state] || DismalTony::ConversationState.new(idle: true, user_identity: self))
      
      possible = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
      @user_data[:uuid] ||= (0..24).each_with_object([]) { |_n, i| i << possible.sample }.join
    end

    # Clones using the Marlshal dump / load trick.
    def clone
      Marshal.load(Marshal.dump(self))
    end

    # A Default user, in case none is provided. Has data for <tt>nickname, first_name, last_name</tt>.
    DEFAULT = DismalTony::UserIdentity.new(
      user_data: {
        nickname: 'User',
        first_name: 'Default',
        last_name: 'User'
      }
    )

    # Syntactic sugar for UserIdentity.conversation_state
    def state
      @conversation_state
    end

    def[]=(left, right) # :nodoc:
      @user_data[left.to_sym] = right
    end

    # Used to access UserIdentity.user_data using +str+ as a key
    def[](str)
      user_data[str.to_sym]
    end

    # Compares if these users have the same user_data hash
    def ==(other)
      return nil unless other.respond_to?(:user_data)
      other.user_data == user_data
    end

    # Uses ConversationState#merge to non-overwritingly merge the +new_state+ into the existing state
    def modify_state(new_state)
      conversation_state.merge(new_state)
    end

    # Uses ConversationState#merge! to overwrite the existing state with the +new_state+
    def modify_state!(new_state)
      conversation_state.merge!(new_state)
    end

    # modifies the +user_data+ by using Hash#merge! with the new +data+
    def modify_user_data(data)
      @user_data.merge!(data)
    end

    # Syntactic sugar for +conversation_state.idle?+
    def idle?
      conversation_state.idle?
    end
  end
end
