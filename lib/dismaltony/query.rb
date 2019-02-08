module DismalTony # :nodoc:
  # Represents the query to the system. Holds the input, and metadata, then stores the result
  class Query
    # The incoming query as pure text.
    # Useful as a fallback in the case that there's no +parsed_result+, and utilized by #=~
    attr_reader :raw_text
    # a collection containing the parsing strategies that were applied
    attr_accessor :parsed_results
    # a UserIdentity object representing the person who made the query
    attr_reader :user

    # Accesses the following keys for the hash +opts+:
    # * :raw_text, The plain string input of the query.
    # Used for #=~ comparisons and as a backup
    # * :parsed_results, the array of parsing strategies
    # * :user, The UserIdentity corresponding to who asked the query.
    def initialize(**opts)
      @raw_text = opts.fetch(:raw_text) { '' }
      @parsed_results = opts.fetch(:parsed_results) { [] }
      @user = opts.fetch(:user) { DismalTony::UserIdentity::DEFAULT }.clone
    end

    # Compares +check+ against +raw_text+ using #=~
    def =~(check)
      raw_text =~ check
    end

    # Redefined to check first if +parsed_results+ can respond to +method_name+, and passes along +params+
    def method_missing(method_name, *params, &blk)
      super unless parsed_results.any? { |r| r.respond_to?(method_name) }
      raise ArgumentError, "Multiple parsed results respond to ##{method_name.to_s}" unless parsed_results.one? { |r| r.respond_to?(method_name) }
      parsed_results.select { |r| r.respond_to?(method_name) }.first.method(method_name).call(*params, &blk)
    end

    # Also checks +mname+ on parsed_results so as to be unsurprising
    def respond_to?(mname, incl = false)
      parsed_results.any? { |r| r.respond_to?(mname) } || super
    end

    # Implicit string conversion
    def to_str
      raw_text
    end
  end
end
