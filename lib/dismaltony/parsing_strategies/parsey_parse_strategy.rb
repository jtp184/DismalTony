require 'ParseyParse'

module DismalTony
  module ParsingStrategies
    class ParseyParseStrategy < ParsingStrategy
      def self.call(q)
        ParseyParse.call(q)
      end

      def self.value_class
        ParseyParse::Sentence
      end
    end
  end
end
