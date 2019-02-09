module DismalTony
  module ParsingStrategies
    class << self
      include Enumerable
    end

    # Selects all inheritors of the Directive class that are defined as constants within this module.
    def self.all
      constants.map { |c| const_get(c) }.select { |c| c < DismalTony::ParsingStrategies::ParsingStrategy }
    end

    # Using #all, returns an each iterator which is passed the block +blk+
    def self.each(&blk)
      all.each(&blk)
    end

    class ParsingStrategy
      def self.call(_q); end
    end
  end
end
