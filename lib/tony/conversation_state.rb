module Tony
  class ConversationState
    attr_accessor :depth
    attr_accessor :queries
    attr_accessor :memory
    attr_accessor :is_finished

    def initialize
      @memory = Hash.new
      @depth = 0
      @queries = Array.new
      @is_finished = false
    end

    def finished?
      @is_finished
    end
  end
end
