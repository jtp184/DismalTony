module DismalTony # :nodoc:
  # Respresents a response to an incoming query. 
  # Handles providing match conditions as well as what to do when matched
  # TODO: Separated Mixins that simplify common functions
  
  module Directives
    class << self
      include Enumerable
    end

    def self.all
      self.constants.map { |c| self.const_get(c) }.select { |c| c <= DismalTony::Directive }
    end

    def self.each(&blk)
      self.all.each(&blk)
    end
    
    def self.in_group(the_group)
      self.all.select { |dir| dir.group == the_group } 
    end
    
    def self.[](param)
      self.all.select { |dir| dir.name == param }.first
    end
  end

  class Directive
    attr_reader :group
    attr_reader :name
    attr_reader :query
    attr_accessor :parameters
    attr_reader :match_criteria
    attr_reader :vi

    class << self
      attr_reader :name #:nodoc:
      attr_reader :group #:nodoc:
      attr_reader :match_criteria #:nodoc:
      attr_reader :default_params

      @default_params = {}

      DismalTony::MatchLogic.priorities.each do |label|
        define_method(label.to_sym) do |&b|
          DismalTony::MatchLogic[label].new(Proc.new(&b))
        end
      end
    end

    def initialize(qry, vi)
      @name = (self.class.name || '')
      @group = (self.class.group || 'none')
      @parameters = (self.class.default_params.clone || {})
      @match_criteria = (self.class.match_criteria || [] )
      @query = qry
      @vi = vi
    end

    def self.error(qry, vi)
      me = new(qry, vi)
      me.query.complete(self, HandledResponse.error)
    end

    def self.add_criteria(&block)
      crit = []
      yield crit
      @match_criteria ||= []
      @match_criteria += crit
    end

    def self.matches?(qry)
      return nil if self.match_criteria.empty?

      certainty = 0.0
      self.match_criteria.each do |crit|
        if crit.is_true?(qry)
          crit.on_succeed
          certainty += crit
        else
          crit.on_failure
          certainty += crit.fail
        end
      end
      certainty / self.match_criteria.select(&:penalty?).length.to_f
    rescue MatchLogicFailure
      return nil
    end

    def self.test_matches(qry)
      self.match_criteria.map do |pri, c| 
        pat = /{.*}/
        x = File.readlines(c.source_location[0])[c.source_location[1] - 1].slice(pat)
        [pri, x, c.(qry)]
      end
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
      @default_params ||= {}
      @default_params[param.to_sym] = initial
    end

    def self.add_params(inputpar)
      inputpar.each do |ki, va|
        @default_params[ki] = va
      end
    end

    def params
      @parameters
    end

    def response
      query.response
    end

    def run; end

    def call(mtd = :run)
      fin = self.method(mtd).call
      raise "No response" unless fin.respond_to? :outgoing_message
      @query.complete(self, fin)
      self 
    end
  end
end