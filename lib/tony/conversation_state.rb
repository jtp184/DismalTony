module Tony
  class ConversationState
    attr_accessor :depth
    attr_accessor :queries
    attr_accessor :memory
    attr_accessor :is_finished

    def initialize
      @memory = {}
      @depth = 0
      @queries = []
      @is_finished = false
    end

    def finished?
      @is_finished
    end
  end
end
