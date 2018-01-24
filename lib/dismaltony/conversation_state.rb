module DismalTony # :nodoc:
  # Represents the state of conversation, to allow for control flow in multi-stage handler resolution
  class ConversationState
    # A Time object referencing the last time this user queried the VI
    attr_reader :last_recieved_time
    # True/False as to whether the VI is in the middle of a chain of handlers
    attr_reader :idle
    # A symbol corresponding to a forcible redirect of which Directive to use next.
    attr_reader :next_directive
    # A symbol representing the method to use next out of +next_directive+
    attr_reader :next_method
    # Any elements passed between elements in a Query resolution chain
    attr_reader :data
    # A used to signal whether to parse the next query or not,
    # useful when asking for followup information.
    attr_reader :parse_next

    # +args+ Options have no defaults by design, allowing values to be nil when necessary.
    # Specify values by using the attribute names as Symbols
    def initialize(**args)
      @last_recieved_time = args[:last_recieved_time]
      @idle = args[:idle]
      @next_directive = args[:next_directive]
      @next_method = args[:next_method]
      @data = args[:data]
      @parse_next = args[:parse_next]
    end

    # Clones using the Marlshal dump / load trick.
    def clone
      Marshal::load(Marshal.dump(self))
    end

    # Syntactic sugar for #idle
    def idle?
      @idle
    end

    # Syntactic sugar for #parse_next 
    def parse_next?
      @parse_next
    end

    # Combines the state of ConversationState +other+ in with this one safely, keeping existing values if +other+ has a nil
    def merge(other)
      @last_recieved_time ||= other.last_recieved_time
      @idle ||= other.idle
      @next_directive ||= other.next_directive
      @next_method ||= other.next_method
      @data ||= other.data
      @parse_next ||= other.parse_next
    end

    # Combines the state of ConversationState +other+ in with this one destructively, overwriting existing values
    def merge!(other)
      @last_recieved_time = other.last_recieved_time
      @idle = other.idle
      @next_directive = other.next_directive
      @next_method = other.next_method
      @data = other.data
      @parse_next = other.parse_next
    end

    # Updates +last_recieved_time+ with a current timestamp
    def stamp
      @last_recieved_time = Time.now
      self
    end
  end
end
