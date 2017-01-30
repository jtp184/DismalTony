module DismalTony
  class HandledResponse
    attr_accessor :return_message
    attr_accessor :conversation_state

    def initialize(rm = '', cs = DismalTony::ConversationState.new)
      @return_message = rm
      @conversation_state = cs
    end

    def to_s
      @return_message
    end

    def self.finish(rm = '')
      new_state = DismalTony::ConversationState.new(:is_idle => true, :use_next => nil, :return_to_handler => nil, :return_to_method => nil, :return_to_args => nil, :data_packet => nil)
      self.new(rm, new_state)
    end

    def self.ask_for(next_handler = DismalTony::QueryHandler.new, data_index = '')
      new_state = DismalTony::ConversationState.new(:is_idle => false, :return_to_handler => next_handler.handler_name, :return_to_method => "set_value", :return_to_args => data_index, :data_packet => next_handler.data)
      self.new(rm, new_state)
    end

    def self.then_do(next_handler = DismalTony::QueryHandler.new, next_method = '', rm = '')
      new_state = DismalTony::ConversationState.new(:is_idle => false, :return_to_handler => next_handler.handler_name, :return_to_method => next_method, :data_packet => next_handler.data)
      self.new(rm, new_state)
    end
  end
end
