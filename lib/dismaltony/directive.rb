module DismalTony # :nodoc:
  # Respresents a response to an incoming query. 
  # Handles providing match conditions as well as what to do when matched
  # TODO: Separated Mixins that simplify common functions
  
  module Directives
    class << self
      include Enumerable
    end

    def self.all
      self.constants.select { |sym| self.const_get(sym).is_a? Class}.map! { |sym| self.const_get(sym)}
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
      @match_criteria = (self.class.match_criteria || [] )
      @query = qry
    end

    def self.error(qry)
      me = new(qry)
      me.query.complete(self, HandledResponse.error)
    end

    def self.add_criteria(&block)
      crit = []
      yield crit
      @match_criteria ||= []
      @match_criteria += crit
    end

    def self.must(&block)
      [:must, Proc.new(&block)]
    end

    def self.should(&block)
      [:should, Proc.new(&block)]
    end

    def self.matches?(qry)
      return nil if self.match_criteria.empty?
      return nil unless self.match_criteria.select { |pri, _c| pri == :must }.all? { |pri, crit| crit.(qry) }
      return (self.match_criteria.select { |_pri, crit| crit.(qry) }).length / self.match_criteria.length.to_f
    end

    class << self
      alias =~ matches?
      alias from new
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

    def response
      query.response
    end

    def run; end

    def call
      fin = run
      @query.complete(self, fin)
      self 
    end
  end
end