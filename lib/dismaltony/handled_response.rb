module DismalTony
  class HandledResponse
    attr_accessor :return_message
    attr_accessor :conversation_state

    def initialize(rm = '', cs = nil, _f = true)
      @return_message = rm
      @conversation_state = cs
    end

    def to_s
      @return_message
    end
  end
end
