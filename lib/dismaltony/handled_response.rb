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
      new_state = DismalTony::ConversationState.new(idle: true, use_next: nil, next_handler: nil, next_method: nil, next_args: nil, data_packet: nil)
      new(rm, new_state)
    end

    def self.ask_for(next_handler = DismalTony::QueryHandler.new, data_index = nil, rm = '') # :nodoc:
      new_state = DismalTony::ConversationState.new(idle: false, next_handler: next_handler.handler_name, next_method: 'set_value', next_args: data_index, data_packet: next_handler.data)
      new(rm, new_state)
    end

    # Produces a new HandledResponse intended to then direct the next User input to a specific handler
    #
    # * +next_handler+ - a QueryHandler object corresponding to the handler
    # * +next_method+ - the name of the desired method inside that handler
    # * +rm+ - the return message to send
    def self.then_do(next_handler = DismalTony::QueryHandler.new, next_method = '', rm = '')
      new_state = DismalTony::ConversationState.new(idle: false, next_handler: next_handler.handler_name, next_method: next_method, data_packet: next_handler.data)
      new(rm, new_state)
    end

    # Allows you to append formatting options +form+ to a Class Method created response easily.
    def with_format(**form)
      @format = form
      self
    end
  end
end
