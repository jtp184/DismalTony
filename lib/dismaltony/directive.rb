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
    attr_reader :vi

    class << self
      attr_reader :name #:nodoc:
      attr_reader :group #:nodoc:
      attr_accessor :parameters #:nodoc:
      attr_reader :match_criteria #:nodoc:
    end

    def initialize(qry, vi)
      @name = (self.class.name || '')
      @group = (self.class.group || 'none')
      @parameters = (self.class.parameters || {})
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

    def self.must(&block)
      [:must, Proc.new(&block)]
    end

    def self.should(&block)
      [:should, Proc.new(&block)]
    end

    def self.could(&block)
      [:could, Proc.new(&block)]
    end

    def self.keyword(&block)
      [:keyword, Proc.new(&block)]
    end

    def self.matches?(qry)
      return nil if self.match_criteria.empty?

      certainty = 0.0
      self.match_criteria.each do |prio, crit|
        case prio
        when :keyword
          if crit.(qry) then certainty += 5 else raise ArgumentError end
        when :must
          if crit.(qry) then certainty += 1 else raise ArgumentError end
          when :should, :could
            certainty +=1 if crit.(qry)
          end 
        end
        return certainty / self.match_criteria.select { |pri, _c| pri != :could }.length.to_f
      rescue ArgumentError
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
        @parameters ||= {}
        @parameters[param.to_sym] = initial
      end

      def self.add_params(params)
        @parameters ||= {}
        params.each do |ki, va|
          @parameters[ki] = va
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