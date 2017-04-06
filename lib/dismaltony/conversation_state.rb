module DismalTony # :nodoc:
  # Represents the state of conversation, to allow for control flow in multi-stage handler resolution
  class ConversationState
    # A UserIdentity object corresponding to the user which has this state
    attr_reader :user_identity
    # A Time object referencing the last time this user queried the VI
    attr_reader :last_recieved_time
    # True/False as to whether the VI is in the middle of a chain of handlers
    attr_reader :is_idle
    # TBI. Allows you to specify the overnext step in a handler chain in addition to a return handler
    attr_reader :use_next
    # Corresponds to the QueryHandler#handler_name of the handler to direct the input to next
    attr_reader :return_to_handler
    # Corresponds to the method name to use within the #return_to_handler
    attr_reader :return_to_method
    # Any arguments for the method to return to
    attr_reader :return_to_args
    # The hash to assign to QueryHandler#data
    attr_reader :data_packet

    # +args+ Options have no defaults by design, allowing values to be nil when necessary.
    # Specify values by using the attribute names as Symbols
    def initialize(**args)
      @last_recieved_time = args[:last_recieved_time]
      @is_idle = args[:is_idle]
      @use_next = args[:use_next]
      @return_to_args = args[:return_to_args]
      @return_to_handler = args[:return_to_handler]
      @return_to_method = args[:return_to_method]
      @user_identity = args[:user_identity]
      @data_packet = args[:data_packet]
    end

    # Syntactic sugar for #is_idle
    def idle?
      @is_idle
    end

    # Combines the state of ConversationState +other+ in with this one safely, keeping existing values if +other+ has a nil
    def merge(other)
      @last_recieved_time = (other.last_recieved_time || @last_recieved_time)
      @is_idle = (other.is_idle || @is_idle)
      @use_next = (other.use_next || @use_next)
      @return_to_args = (other.return_to_args || @return_to_args)
      @return_to_handler = (other.return_to_handler || @return_to_handler)
      @return_to_method = (other.return_to_method || @return_to_method)
      @user_identity = (other.user_identity || @user_identity)
      @data_packet = (other.data_packet || @data_packet)
    end

    # Combines the state of ConversationState +other+ in with this one destructively, overwriting existing values
    def merge!(other)
      @last_recieved_time = other.last_recieved_time
      @is_idle = other.is_idle
      @use_next = other.use_next
      @return_to_args = other.return_to_args
      @return_to_handler = other.return_to_handler
      @return_to_method = other.return_to_method
      @user_identity = other.user_identity
      @data_packet = other.data_packet
    end

    # Takes a hash +args+ with keys corresponding to the attribute to change, and the value to its new value. 
    # Keeps existing values if the hash value is nil.
    def from_h(**args)
      @last_recieved_time = (args[:last_recieved_time] || @last_recieved_time)
      @is_idle = (args[:is_idle] || @is_idle)
      @use_next = (args[:use_next] || @use_next)
      @return_to_args = (args[:return_to_args] || @return_to_args)
      @return_to_handler = (args[:return_to_handler] || @return_to_handler)
      @return_to_method = (args[:return_to_method] || @return_to_method)
      @user_identity = (args[:user_identity] || @user_identity)
      @data_packet = (args[:data_packet] || @data_packet)
    end

    # Syntactic sugar. Returns true if #is_idle or #use_next returns true
    def steer?
      @is_idle || @use_next
    end
  end
end
