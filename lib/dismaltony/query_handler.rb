module DismalTony
  class QueryHandler
    attr_accessor :handler_name
    attr_accessor :patterns
    attr_accessor :data
    attr_accessor :vi

    def initialize(virtual = DismalTony::VIBase.new)
      @vi = virtual
      @patterns = []
      @data = {}
      self.handler_start
      @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
    end

    def error_out
      nil
    end

    def handler_start; end

    def activate_handler!; end

    def activate_handler; end

    def check_understanding(query)
      parse query
      response = 'Okay, I got:\n\n'
      @data.keys.each do |key|
        response += "  #{key}: #{@data[key]}\n"
      end
      response
    end

    def responds?(query)
      parse(query)
    end

    def set_value(index, value)
      @data[index] = value
    end

    def []=(left, right)
      @data[left] = right
    end

    def [](value)
      @data[value]
    end

    def parse(query)
      match_data = nil
      @patterns.each do |pattern|
        match_data ||= pattern.match query
        next if match_data.nil?

        begin
          caps = match_data.named_captures
          @data.merge!(caps) { |_k, _o, n| n} unless match_data.nil?
        rescue Exception => e #on the off chance named captures doesn't work? (Found on Heroku)
          caps = {}
          match_data.names.each do |name|
            caps[name] = match_data[name]
          end
          @data.merge!(caps) { |_k, _o, n| n} unless match_data.nil?
        end

      end
      return match_data
    end
  end
  
  class ExplainHandler < QueryHandler
    def initialize(virtual)
      @vi = virtual
      @handler_name = 'explain-handler'
      @patterns = ['^what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)']
      @data = { 'second_query' => '' }
      @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
    end

    def activate_handler!(query, user)
      parse query
      message = @vi.query(@data['second_query'], user).to_s
      DismalTony::HandledResponse.finish(message)
    end

    def activate_handler(query, user)
      parse query
      "I will explain what I'd do if you asked me \'#{@data['second_query']}\'"
    end
  end

  class CannedResponse < QueryHandler
    attr_accessor :responses

    def initialize(virtual = DismalTony::VIBase.new)
      @vi = virtual
      @patterns = []
      @data = {}
      @responses = []
      self.handler_start
      @patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) } unless @patterns.all? { |e| e.is_a? Regexp }
    end

    def activate_handler(query, user)
      "I'll reply with one of #{@responses.length} responses!"
    end

    def activate_handler!(query, user)
      DismalTony::HandledResponse.finish @responses.sample
    end
  end

  class ResultQuery < QueryHandler
    def apply_format; end
    def query_result; end

    def initialize(virtual)
      super(virtual)
    end

    def activate_handler(_query, _user)
      "I'll calculate the result, and then list it out for you!"
    end

    def activate_handler!(query, user)
      DismalTony::HandledResponse.finish self.apply_format(self.query_result(query, user))
    end
  end

  class QueryMenu < QueryHandler
    attr_accessor :menu_choices

    def add_option(opt_name, response)
      @menu_choices[opt_name] = response
    end

    def initialize(virtual)
      @menu_choices = {}
      super(virtual)
    end

    def activate_handler!(query, user)
      if @data['menu_choice']
        their_choice = @menu_choices[query.to_sym]
        if their_choice.nil?
          DismalTony::HandledResponse.finish "~e:frown I'm sorry, that isn't an option!"
        else
          their_choice
        end
      else
        @data['menu_choice'] = true
        self.menu(query, user)
      end
    end

    def query_result(query, user)
      self.menu_choices
    end

    def activate_handler(query, user)
      "I'll bring you to the list of options for that function!"
    end
  end

  class RemoteControl < QueryHandler
    attr_accessor :actions

    def initialize(virtual)
      @actions = []
      super(virtual)
    end

    def activate_handler(query, user)
      "I'll handle that with the #{@handler_name} handler."
    end

    def activate_handler!(query, user)
      DismalTony::HandledResponse.finish.with_format(:quiet => true)
    end
  end
end
