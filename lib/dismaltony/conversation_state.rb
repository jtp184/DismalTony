module DismalTony # :nodoc:
  # Represents the state of conversation, to allow for control flow in multi-stage handler resolution 
  class ConversationState
    # A UserIdentity object corresponding to the user which has this state
    attr_accessor :user_identity
    # A Time object referencing the last time this user queried the VI
    attr_accessor :last_recieved_time
    # True/False as to whether the VI is in the middle of a chain of handlers
    attr_accessor :is_idle
    # TBI. Allows you to specify the overnext step in a handler chain in addition to a return handler
    attr_accessor :use_next
    # Corresponds to the QueryHandler#handler_name of the handler to direct the input to next
    attr_accessor :return_to_handler
    # Corresponds to the method name to use within the #return_to_handler
    attr_accessor :return_to_method
    # Any arguments for the method to return to
    attr_accessor :return_to_args
    # The hash to assign to QueryHandler#data
    attr_accessor :data_packet

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

    # Clones this ConversationState and then calls #from_h! on it for +the_hash+
    def from_h(the_hash)
      state = clone
      state.from_h!(the_hash)
    end

    # Uses the values in +the_hash+ to overwrte this ConversationState, and returns the new state
    def from_h!(the_hash)
      the_hash.each_pair { |key, value| method("#{key}=".freeze).call(value) }
      the_hash
    end

    def to_h # :nodoc:
      the_hash = {}
      instance_variables.each do |var|
        # next if var == :@user_identity
        var = (var.to_s.gsub(/\@(.+)/) { |_match| Regexp.last_match(1) }).to_sym
        the_hash[var] = method(var).call
      end
      the_hash
    end

    # Syntactic sugar. Returns true if #is_idle or #use_next do
    def steer?
      @is_idle || @use_next
    end
  end
end
