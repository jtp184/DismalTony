module DismalTony # :nodoc:

  # Represents the identity of the user submitting queries. Used both to allow for stated conversation,
  # and as a way to keep user-specific information isolated from other user-specific information, such as
  # names, phone numbers, preferences, etc. 
  class UserIdentity
    # A Hash. +user_data+ keeps track of unique information. Calling <tt>UserIdentity[key]</tt> retrieves from here.
    attr_accessor :user_data
    # A ConversationState object corresponding to this user's conversation state.
    attr_accessor :conversation_state

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
        :user_data => {
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

    # Uses ConversationState.from_h! to apply the changes from +new_state+
    def modify_state(new_state)
      @conversation_state.from_h! new_state.to_h
    end
  end
end
