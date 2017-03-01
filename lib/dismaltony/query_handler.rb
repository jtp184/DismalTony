require 'json'

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

    def data_json
      @data.to_json
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
end
