module DismalTony # :nodoc:
  # Represents the state of conversation, to allow for control flow in multi-stage handler resolution
  class ConversationState
    # A Time object referencing the last time this user queried the VI
    attr_reader :last_recieved_time
    # True/False as to whether the VI is in the middle of a chain of handlers
    attr_reader :idle
    # Corresponds to the QueryHandler#handler_name of the handler to direct the input to next
    attr_reader :next_handler
    # Corresponds to the method name to use within the #next_handler
    attr_reader :next_method
    # Any arguments for the method to return to
    attr_reader :next_args
    # The hash to assign to QueryHandler#data
    attr_reader :data_packet

    # +args+ Options have no defaults by design, allowing values to be nil when necessary.
    # Specify values by using the attribute names as Symbols
    def initialize(**args)
      @last_recieved_time = args[:last_recieved_time]
      @idle = args[:idle]
      @next_args = args[:next_args]
      @next_handler = args[:next_handler]
      @next_method = args[:next_method]
      @data_packet = args[:data_packet]
    end

    # Syntactic sugar for #idle
    def idle?
      @idle
    end

    # Combines the state of ConversationState +other+ in with this one safely, keeping existing values if +other+ has a nil
    def merge(other)
      @last_recieved_time = (other.last_recieved_time || @last_recieved_time)
      @idle = (other.idle || @idle)
      @next_args = (other.next_args || @next_args)
      @next_handler = (other.next_handler || @next_handler)
      @next_method = (other.next_method || @next_method)
      @data_packet = (other.data_packet || @data_packet)
    end

    # Combines the state of ConversationState +other+ in with this one destructively, overwriting existing values
    def merge!(other)
      @last_recieved_time = other.last_recieved_time
      @idle = other.idle
      @next_args = other.next_args
      @next_handler = other.next_handler
      @next_method = other.next_method
      @data_packet = other.data_packet
    end

    # Takes a hash +args+ with keys corresponding to the attribute to change, and the value to its new value.
    # Keeps existing values if the hash value is nil.
    def from_h(**args)
      @last_recieved_time = (args[:last_recieved_time] || @last_recieved_time)
      @idle = (args[:idle] || @idle)
      @next_args = (args[:next_args] || @next_args)
      @next_handler = (args[:next_handler] || @next_handler)
      @next_method = (args[:next_method] || @next_method)
      @data_packet = (args[:data_packet] || @data_packet)
    end
  end
end
