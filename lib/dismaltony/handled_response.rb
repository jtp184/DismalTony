module DismalTony
  class HandledResponse
    attr_accessor :return_message

    def initialize(rm = '')
      @return_message = rm
    end

    def to_s
      @return_message
    end

    def finish(rm = '')
      self.new(rm)
    end

    def ask_for()
    end

    def then_do(next_one = '', rm = '')
      self.new(rm)
    end
  end
end
