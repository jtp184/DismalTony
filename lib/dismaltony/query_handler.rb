module DismalTony
  class QueryHandler
    attr_accessor :handler_name
    attr_accessor :patterns
    attr_accessor :data
    attr_accessor :vi

    def initialize(virtual)
      @vi = virtual
      self.handler_start
    end

    class << self
      attr_reader :list
    end
    @list = []

    def self.inherited(klass)
      @list << klass
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

    def parse(query)
      did = false
      @patterns.each do |pattern|
        match_data = pattern.match query
        next if match_data.nil?
        did = true
        @data.merge!(match_data.named_captures) { |_k, _o, n| n}
      end
      return did
    end
  end
end
