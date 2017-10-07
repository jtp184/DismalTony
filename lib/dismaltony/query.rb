module DismalTony # :nodoc:
  # Represents the query to the system. Holds the input, and metadata, then stores the result
  class Query

    # The incoming query as pure text. 
    # Useful as a fallback in the case that there's no +parsed_result+
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
    # the Directive was is triggered by the query
    attr_reader :directive
    # a Time object for when the query completed
    attr_reader :completed_at


    def initialize(**opts)
      @raw_text = opts[:raw_text]
      @parsed_result = opts[:parsed_result]
      @user = opts[:user].clone
      @timestamp = Time.now
      @previous_state = @user&.state&.clone
    end

    def complete(directive, hr)
      @directive = directive
      @completed_at = Time.now
      @response = hr
      self
    end

    def =~(check)
      raw_text =~ check
    end

    def method_missing(method_name, *params)
      if parsed_result.respond_to?(method_name)
        parsed_result.method(method_name).(*params)
      else
        super
      end
    end
  end
end