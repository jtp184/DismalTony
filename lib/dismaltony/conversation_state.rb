module DismalTony # :nodoc:
  # Represents the state of conversation, to allow for control flow in multi-stage handler resolution
  class ConversationState
    # The hash containing the options
    # - :last_recieved_time
    # -- A Time object referencing the last time this user queried the VI
    # - :idle
    # -- True/False as to whether the VI is in the middle of a chain of handlers
    # - :next_directive
    # -- A symbol corresponding to a forcible redirect of which Directive to use next.
    # - :next_method
    # -- A symbol representing the method to use next out of +next_directive+
    # - :data
    # -- Any elements passed between elements in a Query resolution chain
    # - :parse_next
    # -- A used to signal whether to parse the next query or not.    attr_reader :options
    attr_reader :options
    # +args+ Options have no defaults by design, allowing values to be nil when necessary.
    # Specify values by using the attribute names as Symbols
    def initialize(**args)
      @options = {}
      @options[:last_recieved_time] = args.fetch(:last_recieved_time) { nil }
      @options[:idle] = args.fetch(:idle) { nil }
      @options[:next_directive] = args.fetch(:next_directive) { nil }
      @options[:next_method] = args.fetch(:next_method) { nil }
      @options[:data] = args.fetch(:data) { nil }
      @options[:parse_next] = args.fetch(:parse_next) { nil }
    end

    # Clones using the Marlshal dump / load trick.
    def clone
      Marshal.load(Marshal.dump(self))
    end

    # Syntactic sugar for #idle
    def idle?
      @options.fetch(:idle)
    end

    # Syntactic sugar for #parse_next
    def parse_next?
      @options.fetch(:parse_next)
    end

    def method_missing(m_name, *args) # :nodoc:
      @options.fetch(m_name)
    rescue KeyError
      super
    end

    # Combines the state of ConversationState +other+ in with this one safely, keeping existing values if +other+ has a nil
    def merge(other)
      @options[:last_recieved_time] ||= other.last_recieved_time
      @options[:idle] ||= other.idle
      @options[:next_directive] ||= other.next_directive
      @options[:next_method] ||= other.next_method
      @options[:data] ||= other.data
      @options[:parse_next] ||= other.parse_next
    end

    # Combines the state of ConversationState +other+ in with this one destructively, overwriting existing values
    def merge!(other)
      @options[:last_recieved_time] = other.last_recieved_time
      @options[:idle] = other.idle
      @options[:next_directive] = other.next_directive
      @options[:next_method] = other.next_method
      @options[:data] = other.data
      @options[:parse_next] = other.parse_next
    end

    # Updates +last_recieved_time+ with a current timestamp
    def stamp
      @options[:last_recieved_time] = Time.now
      self
    end
  end
end
