require 'ParseyParse'

module DismalTony
  module ParsingStrategies
    class ParseyParseStrategy < ParsingStrategy
      def self.call(q)
        ParseyParse.call(q)
      end
    end
  end
end
