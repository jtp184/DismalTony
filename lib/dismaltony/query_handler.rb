module DismalTony # :nodoc:

  # The basic method to handle queries. Comes with lots of built in logic to help subclassing, 
  # or just writing clear handlers from the base class.
  class QueryHandler
    # The name of the handler. Must be unique
    attr_accessor :handler_name
    # An Array of Regexps corresponding to queries that you want this Handler to be used for
    attr_accessor :patterns
    # The results of the query being parsed are stored in this hash, to ease using that input in handlers.
    attr_accessor :data
    # A VIBase object corresponding to the VI running the query.
    attr_accessor :vi

    # Instanciates this handler for use, using +virtual+ as the VI.
    # 
    # Also sets the #patterns and #data attributes to blank values, then runs handler_start for itself.
    # Finally, if the patterns aren't already Regexps, they're mapped into literals using the //i option.
    # This can be useful if you want to use interpolation in your patterns, like inserting the VI's name.
    def initialize(virtual = DismalTony::VIBase.new)
      @vi = virtual
      @patterns = []
      @data = {}
      handler_start
      @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
    end

    def error_out # :nodoc:
      nil
    end

    # A setup function that each handler individually declares. Used to set the values of +handler_name+, +patterns+, and any other instance variables.
    def handler_start; end

    # Hard Query. This is the method used to execute the individual handler's purpose, and must return a HandledResponse.
    # 
    # Passes in the +_query+ and the +_user+ for use in resolving the handler.
    def activate_handler!(_query, _user); end

    # Soft Query. Used with the ExplainHandler to let you check the outcome of your query before actually running it. Must return a String.
    # 
    # Passes in the +_query+ and +_user+ for use, although they can be unnecessary.
    def activate_handler(_query, _user); end

    # Checks to see what the VI understood from the +query+. Usually just for debugging your Regexps, it just calls #parse and then lists the contents of #data
    def check_understanding(query)
      parse query
      response = 'Okay, I got:\n\n'
      @data.keys.each do |key|
        response += "  #{key}: #{@data[key]}\n"
      end
      response
    end

    # Syntactic sugar for setting values in #data.
    # 
    # Sets the data +index+ equal to +value+
    def set_value(index, value)
      @data[index] = value
    end


    def []=(left, right) # :nodoc:
      @data[left] = right
    end

    # Accesses the +value+ of #data
    def [](value)
      @data[value]
    end

    # Main query resolution function. Takes the +query+ string, and iterates through #patterns checking for a match.
    # If it finds one, it takes the captures and merges them into the #data hash. 
    # Returns +match_data+ for the query, in case you want to use the actual MatchData object for something.
    def parse(query)
      match_data = nil
      @patterns.each do |pattern|
        match_data ||= pattern.match query
        next if match_data.nil?

        begin
          caps = match_data.named_captures
          @data.merge!(caps) { |_k, _o, n| n } unless match_data.nil?
        rescue Exception # on the off chance named captures doesn't work? (Found on Heroku)
          caps = {}
          match_data.names.each do |name|
            caps[name] = match_data[name]
          end
          @data.merge!(caps) { |_k, _o, n| n } unless match_data.nil?
        end
      end
      match_data
    end

    # Syntactic sugar. 
    # Technically returns the same thing as just parsing the +query+ 
    # but since that value is apropriately truthy, this works just as well.
    alias_method :responds?, :parse
  end

  # Currently the only built-in handler. Matches <tt>/what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)/i</tt> and runs QueryHandler.activate_handler on the handler triggered by the second query.
  class ExplainHandler < QueryHandler

    # Instanciates this handler with the VIBase +virtual+, and sets values for the handler:
    # * +handler_name+ - 'explain-handler'
    # * +patterns+ - <tt>[/what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)/i]</tt>
    def initialize(virtual)
      @vi = virtual
      @handler_name = 'explain-handler'
      @patterns = [/what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)/i]
        @data = { 'second_query' => '' }
        @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
      end

    # Parses the +query+, then returns a HandledResponse corresponding to calling VIBase.query for the +user+ on the second query
    def activate_handler!(query, user)
      parse query
      message = @vi.query(@data['second_query'], user).to_s
      DismalTony::HandledResponse.finish(message)
    end

    # Soft handles a +_user+ +query+ for the ExplainHandler. Somewhat amusingly meta.
    def activate_handler(query, _user)
      parse query
      "I will explain what I'd do if you asked me \'#{@data['second_query']}\'"
    end
  end

  # Subclass responsible for doing simple call/response handlers, like greeters or Help descriptions
  class CannedResponse < QueryHandler
    # An Array of Strings corresponding to the possible replies
    attr_accessor :responses

    # Same as QueryHandler except this initializes #responses as well as instanciating this handler under +virtual+
    def initialize(virtual = DismalTony::VIBase.new)
      @vi = virtual
      @patterns = []
      @data = {}
      @responses = []
      handler_start
      @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
    end

    # Defaults to "I'll reply with one of #{@responses.length} responses!" regardless of the values of +_query+ and +_user+
    def activate_handler(_query, _user)
      "I'll reply with one of #{@responses.length} responses!"
    end

    # Regardless of the values of +_query+ and +_user+, returns a HandledResponse with a message that is a random choice from the #responses array
    def activate_handler!(_query, _user)
      DismalTony::HandledResponse.finish @responses.sample
    end
  end

  # Designed to be accessed both programatically and via querying.
  # Useful for building handlers that simply transmit information, like the contents of a list, or a user's phone number.
  # Handlers written with this subclass can then return the actual Ruby object result from one method, and have a wrapper method 
  # around #activate_handler! that formats it for a User, allowing you to use your handlers in-line in other handlers.
  class ResultQuery < QueryHandler
    # The formatting method. The result of #query_result is sent to this method's +_input+ 
    # method before being used as the responding message for a HandledResponse.
    # Use it to create a user-friendly text representation of the results of the query, like a list(-item) or numerical value.
    def apply_format(_input); end

    # Takes the place of #activate_handler! in being the main resolution method.
    # Parses the +_query+ for the +_user+ and then returns the result as a Ruby object, 
    # instead of returning a HandledResponse description of the result of the Query
    def query_result(_query, _user); end

    def initialize(virtual) # :nodoc:
      super(virtual)
    end

    # Regardless of the values of +_query+ and +_user+, returns <tt>"I'll calculate the result, and then list it out for you!"</tt>
    def activate_handler(_query, _user) 
      "I'll calculate the result, and then list it out for you!"
    end

    # Returns a HandledResponse whose message is the result of running #apply_format on the result of #query_result for +query+ and +user+
    def activate_handler!(query, user)
      DismalTony::HandledResponse.finish apply_format(query_result(query, user))
    end
  end

  # Used to create branching handlers easily.
  class QueryMenu < QueryHandler
    # A Hash of Symbol keyed HandledResponse objects corresponding to the result of choosing different menu options
    attr_accessor :menu_choices

    # Syntactic sugar. Adds +response+ to #menu_choices with a key of +opt_name+
    def add_option(opt_name, response)
      @menu_choices[opt_name] = response
    end

    # Same as QueryHandler.new except it also initializes #menu_choices as an empty array as well as setting the VI to +virtual+
    def initialize(virtual)
      @menu_choices = {}
      super(virtual)
    end

    # Handles this +query+ for the +user+
    # 
    # Checks to see if, after parsing the query, there is a value for <tt>data['menu_choice']</tt>.
    # If so, it tries to return the value corresponding to that key (cast to Symbol) in #menu_choices.
    # If that key doesn't exist, it returns a HandledResponse saying so, otherwise it returns the HandledResponse in the menu.
    # 
    # If it doesn't find a value for <tt>data['menu_choice']</tt>, it calls #menu to present the user with the options.
    def activate_handler!(query, user)
      parse query
      if @data['menu_choice']
        their_choice = @menu_choices[@data['menu_choice'].to_sym]
        return DismalTony::HandledResponse.finish "~e:frown I'm sorry, that isn't an option!" if their_choice.nil?
        their_choice
      else
        menu(query, user)
      end
    end

    # Used to list the menu options to the +_user+. 
    # 
    # If this handler responds to the +_query+, but doesn't have match data for <tt>menu_choice</tt>, then this method is called.
    def menu(_query, _user); end

    # Special method to make all QueryMenu handlers compatible with ResultQuery handlers.
    # Returns #menu_choices regardless of the values of +_query+ and +_user+
    def query_result(_query, _user)
      @menu_choices
    end

    # Regardless of the values of +_query+ and +_user+, outputs <tt>"I'll bring you to the list of options for that function!"</tt>
    def activate_handler(_query, _user)
      "I'll bring you to the list of options for that function!"
    end
  end

  # Used to group together handlers and actions with a like purpose.
  # Kind of like a mini-API handler.
  class SubHandler < QueryHandler
    # An array containing method names corresponding to valid actions.
    # 
    # Any valid action must be of the form <tt>def action_name(opts); end</tt>, and return a HandledResponse
    # but the handler may have other support methods not included in this array which don't use this structure.
    attr_accessor :actions

    # Instanciates this handler under +virtual+ the same as QueryHandler.new does, and instanciates #actions as an empty array
    def initialize(virtual)
      @actions = []
      super(virtual)
    end

    # Defaults to <tt>"I'll handle that with the #{@handler_name} handler."</tt> and disregards +_query+ and +_user+
    def activate_handler(_query, _user)
      "I'll handle that with the #{@handler_name} handler."
    end

    # Hard Query. Defaults to an empty HandledResponse with quiet formatting, disregarding +_user+ and +_query+
    def activate_handler!(_query, _user)
      DismalTony::HandledResponse.finish.with_format(quiet: true)
    end
  end
end
