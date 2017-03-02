module DismalTony
  class ConversationState
    attr_accessor :user_identity
    attr_accessor :last_recieved_time
    attr_accessor :is_idle
    attr_accessor :use_next
    attr_accessor :return_to_handler
    attr_accessor :return_to_method
    attr_accessor :return_to_args
    attr_accessor :data_packet

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

    def idle?
      @is_idle
    end

    def from_h(the_hash)
      state = self.clone
      state.from_h!(the_hash)
      return state
    end

    def from_h!(the_hash)
      the_hash.each_pair { |key, value| self.method("#{key}=".freeze).call(value) }
    end

    def to_h
      the_hash = {}
      self.instance_variables.each do |var|
        # next if var == :@user_identity
        var = ((var.to_s).gsub(/\@(.+)/) { |match| $1 }).to_sym
        the_hash[var] = self.method(var).call
      end
      return the_hash
    end

    def steer?
      @is_idle || @use_next
    end

    def resume(virtual = DismalTony::VIBase.new, query)
      handle = @return_to_handler.new(virtual)
      handle.data = @data_packet
      handle.method(@return_to_method.to_sym).call(query)
    end

    # def +(other)
    #   raise ArgumentError, "Can only modify with another ConversationState (not a #{other.class})" unless other.is_a? DismalTony::ConversationState
    #   current_state = self.to_h
    #   new_state = other.to_h
    #   combine = current_state.merge(new_state) { |key, old_value, new_value| new_value }
    #   self.from_h! combine
    # end

  end
end
