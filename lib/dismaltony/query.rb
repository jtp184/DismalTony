module DismalTony # :nodoc:
  # Represents the query to the system. Holds the input, and metadata, then stores the result
  class Query
    # The incoming query as pure text.
    # Useful as a fallback in the case that there's no +parsed_result+, and utilized by #=~
    attr_reader :raw_text
    # The result of the text being run through a NLU analysis, should be a ParseyParse::Sentence
    attr_reader :parsed_result
    # a UserIdentity object representing the person who made the query
    attr_reader :user

    # Accesses the following keys for the hash +opts+:
    # * :raw_text, The plain string input of the query.
    # Used for #=~ comparisons and as a backup
    # * :parsed_result, An object representing the parsed result. Should be a ParseyParse sentence.
    # * :user, The UserIdentity corresponding to who asked the query.
    def initialize(**opts)
      @raw_text = opts.fetch(:raw_text) { '' }
      @parsed_result = opts.fetch(:parsed_result) { ParseyParse::Sentence.new }
      @user = opts.fetch(:user) { DismalTony::UserIdentity::DEFAULT }.clone
    end

    # Compares +check+ against +raw_text+ using #=~
    def =~(check)
      raw_text =~ check
    end

    # Redefined to check first if +parsed_result+ can respond to +method_name+, and passes along +params+
    def method_missing(method_name, *params, &blk)
      if parsed_result.respond_to?(method_name)
        parsed_result.method(method_name).call(*params, &blk)
      else
        super
      end
    end

    # Implicit string conversion
    def to_str
      raw_text
    end
  end
end
