module DismalTony # :nodoc:
  # The module that contains all the Directive classes. Self enumerates.
  module Directives
    class << self
      include Enumerable
    end

    # Selects all inheritors of the Directive class that are defined as constants within this module.
    def self.all
      constants.map { |c| const_get(c) }.select { |c| c <= DismalTony::Directive }
    end

    # Using #all, returns an each iterator which is passed the block +blk+
    def self.each(&blk)
      all.each(&blk)
    end

    # Returns all Directives whose Directive#group variable is +the_group+
    def self.in_group(the_group)
      all.select { |dir| dir.group == the_group }
    end

    # Takes in the +param+ and returns the first Directive whose Directive#name is +param+
    def self.[](param)
      all.select { |dir| dir.name == param }.first
    end
  end

  # Respresents a response to an incoming query.
  # Handles providing match conditions as well as what to do when matched
  class Directive
    include DismalTony::DirectiveHelpers::CoreHelpers
    # A core function which confirms if the Query +qry+ can be served by this directive.
    # Iterates through the +match_criteria+, and tallies a certainty index. Some MatchCriteria
    # may throw a MatchLogicFailure error, which causes this function to return a nil
    def self.matches?(qry)
      return nil if match_criteria.empty?

      certainty = 0.0
      match_criteria.each do |crit|
        if crit.is_true?(qry)
          crit.on_succeed
          certainty += crit
        else
          crit.on_failure
          certainty += crit.fail
        end
      end
      certainty / match_criteria.select(&:penalty?).length.to_f
    rescue MatchLogicFailure
      nil
    end

    # Takes in the Query +qry+ and verbosely checks it against the +match_criteria+
    # including a string representation of the original code block.
    def self.test_matches(qry)
      match_criteria.map do |crit|
        pat = /{.*}/
        x = File.readlines(crit.predicate.source_location[0])[crit.predicate.source_location[1] - 1].slice(pat)
        [crit.priority, x, crit.predicate.call(qry)]
      end
    end

    class << self
      alias =~ matches?
      alias from new
    end
  end

  class Directive
    # The group this Directive belongs to. Can be used to selectively load some but not all Directives.
    attr_reader :group

    # The name of the Directive, used to uniquely identify it.
    attr_reader :name

    # the Query evaluated by this directive.
    attr_reader :query

    # The hash of values captured and/or returned by this Directive.
    attr_accessor :parameters

    # The MatchLogic criteria objects used to verify whether a Query matches or not.
    attr_reader :match_criteria

    # The VI used to evaluate this Query.
    attr_reader :vi

    class << self
      attr_reader :name #:nodoc:
      attr_reader :group #:nodoc:
      attr_reader :match_criteria #:nodoc:
      # The default parameters set up by the class.
      attr_reader :default_params

      @default_params = {}

      DismalTony::MatchLogicTypes.priorities.each do |label|
        define_method(label.to_sym) do |&b|
          DismalTony::MatchLogicTypes[label].new(Proc.new(&b))
        end
      end
    end

    # Takes in the Query +qry+ and VIBase +vi+ and sets its values,
    # inheriting from class-instance variables when apropriate.
    def initialize(qry, vi)
      @name = (self.class.name || '')
      @group = (self.class.group || 'none')
      @parameters = (self.class.default_params&.clone || {})
      @match_criteria = (self.class.match_criteria || [])
      @query = qry
      @vi = vi
    end

    # Searches the +parameters+ hash using +indx+
    def [](indx)
      @parameters[indx]
    end

    # Returns the response from this directive's +query+
    def response
      query.response
    end

    # Overridden by child classes. The default method used by the
    # #call function to respond to a matched Query.
    def run; end

    # Executes a method +mtd+ on this directive. Defaults to executing
    # the #run method for some syntactic sugar.
    def call(mtd = :run)
      fin = method(mtd).call
      raise "No response (#{fin.inspect})" unless fin.respond_to? :outgoing_message

      @query.complete(self, fin)
      self
    end

    # Returns the query's response if it's completed
    def to_s
      query.complete? ? query.response.to_s : super
    end
  end
end
