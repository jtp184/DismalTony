module DismalTony # :nodoc:
  # Represents the result of running VIBase#query! for a query.
  # Functions as a rich join of the return message and the changed conversation state, with formatting options.
  class HandledResponse
    # The VI's reply to a query. Whatever you want said back to the user.
    attr_reader :outgoing_message
    # A ConversationState object representing the User's new state after running the query
    attr_reader :conversation_state
    # Formatting options for how to display the return message
    attr_reader :format

    # Creates a new response with +rm+ serving as the outgoing message, and +cs+ the conversation state
    def initialize(rm = '', cs = DismalTony::ConversationState.new)
      @outgoing_message = rm
      @conversation_state = cs
      @format = {}
    end

    # Clones using the Marlshal dump / load trick.
    def clone
      Marshal::load(Marshal.dump(self))
    end

    # Returns #outgoing_message
    def to_s
      @outgoing_message
    end

    # Returns the error response, which is the same as #finish with a message of <tt>"~e:frown I'm sorry, I didn't understand that!"</tt>
    def self.error
      finish("~e:frown I'm sorry, I didn't understand that!")
    end

    # Produces a new HandledResponse with a blank ConversationState and a return message of +rm+
    def self.finish(rm = '')
      new_state = DismalTony::ConversationState.new(idle: true, use_next: nil, next_directive: nil, next_method: nil, data: nil, parse_next: true)
      new(rm, new_state)
    end

    # Creates a response whose ConversationState redirects control flow. Passes on next_directive, next_method, data, and parse_next via the +opts+ hash.
    def self.then_do(**opts)
      new_state = DismalTony::ConversationState.new(idle: false, next_directive: opts[:directive].name, next_method: (opts[:method] || :run), data: opts[:data], parse_next: opts.fetch(:parse_next) { true } )
      new(opts[:message], new_state)
    end

    # Allows you to append formatting options +form+ to a Class Method created response easily.
    def with_format(**form)
      @format = form
      self
    end
  end
end
