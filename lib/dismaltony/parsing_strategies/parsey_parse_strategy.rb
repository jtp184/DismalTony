require 'ParseyParse'

module DismalTony # :nodoc:
  module ParsingStrategies # :nodoc:
    # Uses ParseyMcParseface for syntax tagging
    class ParseyParseStrategy < ParsingStrategy
      # Calls ParseyParse with the query +q+
      def self.call(q)
        ParseyParse.call(q)
      end

      def self.value_class # :nodoc:
        ParseyParse::Sentence
      end
    end
  end
end
