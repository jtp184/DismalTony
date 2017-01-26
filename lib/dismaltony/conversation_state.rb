module DismalTony
  class ConversationState
    attr_accessor :the_user
    attr_accessor :last_recieved_time
    attr_accessor :is_idle
    attr_accessor :use_next
    attr_accessor :return_to_handler
    attr_accessor :return_to_method

    def initialize(**args)
      @last_recieved_time = args[:last_recieved_time]
      @is_idle = args[:is_idle]
      @use_next = args[:use_next]
      @return_to_handler = args[:return_to_handler]
      @return_to_method = args[:return_to_method]
      @the_user = args[:the_user]
    end

    def idle?
      @is_idle
    end

    def steer?
      @is_idle || @use_next
    end

  end
end
