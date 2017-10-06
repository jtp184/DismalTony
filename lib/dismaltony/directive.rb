module DismalTony # :nodoc:
  # Respresents a response to an incoming query. 
  # Handles providing match conditions as well as what to do when matched
  # TODO: Separated Mixins that simplify common functions
  
  module Directives
    class << self
      include Enumerable
    end

    def self.all
      self.each.to_a
    end

    def self.each
      valids = self.constants.select { |sym| self.const_get(sym).is_a? Class}
      valids.map! { |sym| self.const_get(sym)}
      valids.each do |val|
        yield val
      end
    end
    
    def self.in_group(the_group)
      self.select { |dir| dir.group == the_group } 
    end
    
    def self.[](param)
      self.select { |dir| dir.name == param }.first
    end
  end

  class Directive
    attr_reader :group
    attr_reader :name
    attr_reader :query
    attr_accessor :parameters
    attr_reader :match_criteria

    @match_criteria = {:unparsed => [], :parsed => []}

    class << self
      attr_reader :name #:nodoc:
      attr_reader :group #:nodoc:
      attr_accessor :parameters #:nodoc:
      attr_reader :match_criteria #:nodoc:
    end

    def initialize(qry)
      @name = (self.class.name || '')
      @group = (self.class.group || 'none')
      @parameters = (self.class.parameters || {})
      @match_criteria = (self.class.match_criteria || {:unparsed => [], :parsed => []})
      @query = qry
    end

    def self.match_on(&block)
      crit = []
      yield crit
      @match_criteria ||= {}
      @match_criteria[:unparsed] = crit
    end

    def self.matches?(qry)
      crits = self.match_criteria

      unpar = crits[:unparsed].all? { |crit| crit.call(qry.raw_text) } unless crits[:unparsed].nil?
      par = crits[:parsed].all? { |crit| crit.call(qry.parsed_result) } unless qry.parsed_result.nil?

      [unpar, par].reject!(&:nil?).all?
    end

    class << self
      alias matches? =~
    end

    def self.match_on_parsed(&block)
      parpar = []
      yield parpar
      @match_criteria ||= {}
      @match_criteria[:parsed] = parpar
    end

    def self.criterion(&block)
      return block
    end

    def self.set_name(param)
      @name = param
    end

    def self.set_group(param)
      @group = param
    end    

    def self.add_param(param, initial = nil)
      @parameters ||= {}
      @parameters[param.to_sym] = initial
    end

    def self.add_params(params)
      @parameters ||= {}
      params.each do |ki, va|
        @parameters[ki] = va
      end
    end

    def run

    end
  end
end