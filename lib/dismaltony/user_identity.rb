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
      @conversation_state = (args[:conversation_state] || DismalTony::ConversationState.new(is_idle: true, user_identity: self))
    end

    # A Default user, in case none is provided. Has data for <tt>nickname, first_name, last_name</tt>.
    DEFAULT = DismalTony::UserIdentity.new(
      user_data: {
        'nickname' => 'User',
        'first_name' => 'Default',
        'last_name' => 'User'
      }
    )

    # Syntactic sugar for UserIdentity.conversation_state
    def state
      @conversation_state
    end

    def[]=(left, right) # :nodoc:
      @user_data[left] = right
    end

    # Used to access UserIdentity.user_data using +str+ as a key
    def[](str)
      @user_data[str]
    end

    # Compares if these users have the same user_data hash
    def ==(other)
      other.user_data == user_data
    end

    # Uses ConversationState#merge to non-overwritingly merge the +new_state+ into the existing state
    def modify_state(new_state)
      @conversation_state.merge(new_state)
    end

    # Uses ConversationState#merge! to overwrite the existing state with the +new_state+
    def modify_state!(new_state)
      @conversation_state.merge!(new_state)
    end
  end
end
