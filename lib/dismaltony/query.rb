module DismalTony # :nodoc:
  # Represents the query to the system. Holds the input, and metadata, then stores the result
  class Query

    # The incoming query as pure text. 
    # Useful as a fallback in the case that there's no +parsed_result+, and utilized by #=~
    attr_reader :raw_text
    # The result of the text being run through a NLU analysis, should be a ParseyParse::Sentence
    attr_reader :parsed_result
    # A UserIdentity corresponding to the user who submitted the query.
    attr_reader :user
    # A Time object representing when the query was submitted
    attr_reader :timestamp
    # a ConversationState representing the state of +user+ before the query is run.
    attr_reader :previous_state
    # a ConversationState representing the state of +user+ after the query is run.
    attr_reader :response
    # the Directive that is triggered by the query
    attr_reader :directive
    # a Time object for when the query completed
    attr_reader :completed_at

    # Accesses the following keys for the hash +opts+:
    # * :raw_text, The plain string input of the query. 
    # Used for #=~ comparisons and as a backup
    # * :parsed_result, An object representing the parsed result. Should be a ParseyParse sentence.
    # * :user, The UserIdentity corresponding to who asked the query.
    def initialize(**opts)
      @raw_text = opts.fetch(:raw_text) { "" }
      @parsed_result = opts.fetch(:parsed_result) { ParseyParse::Sentence.new}
      @user = opts.fetch(:user) { DismalTony::UserIdentity::DEFAULT }.clone
      @timestamp = Time.now
      @previous_state = @user&.state&.clone
    end


    # Completes the query using the Directive +directive+ and HandledResponse +hr+ that are yielded.
    def complete(directive, hr)
      @directive = directive
      @completed_at = Time.now
      @response = hr
      self
    end

    # Compares +check+ against +raw_text+ using #=~
    def =~(check)
      raw_text =~ check
    end

    # Redefined to check first if +parsed_result+ can respond to +method_name+, and passes along +params+
    def method_missing(method_name, *params)
      if parsed_result.respond_to?(method_name)
        parsed_result.method(method_name).(*params)
      else
        super
      end
    end

    # Checks to see both if there's a +completed at+ timestamp and a +response+
    def complete?
      completed_at && response
    end
  end
end