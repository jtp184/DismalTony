module DismalTony
  # Represents a prescriptive check to see if a Query can be paired with a Directive.
  # Self enumerating, and each priority is transformed into a DSL method that can be used to create it.
  class MatchLogic
    # The word used in DSL to indicate this type of MatchLogic, stored as a symbol
    attr_accessor :priority
    # The Proc representing the condition to compare the Query against.
    attr_accessor :predicate
    # A value to change the certainty factor by when this match succeeds.
    attr_reader :succeeds_incr
    # A value to change the certainty factor by when this match fails.
    attr_reader :fails_incr
    # Whether this logic type should be counted or abstained from counting when evaluating matching criteria.
    attr_reader :penalty

    # Takes in a predicate +pre+ which is a Proc object of arity 1 representing the condition to check against.
    # Subclasses can override values such as the +priority+, +succeeds_incr+, and +fails_incr+, and +penalty+ status.
    # Otherwise, they default to :matches, 1, 0, and true respectively.
    def initialize(pre)
      @predicate = pre
      @priority = :matches
      @succeeds_incr = 1
      @fails_incr = 0
      @penalty = true
    end

    # Kickback method. When a +subclass+ is created, it's added to the +members+ array.
    def self.inherited(subclass)
      DismalTony::MatchLogicTypes << subclass
    end

    # Adds +succeeds_incr+ to +other+ and returns the result
    def +(other)
      @succeeds_incr + other
    end

    # Returns the proper format of an Array of +other+ and +succeeds_incr+ converted to float
    def coerce(other)
      [other, @succeeds_incr.to_f]
    end

    # returns the fail value instead of the success value.
    def fail
      @fails_incr
    end

    # Returns true if +penalty+ does.
    def penalty?
      @penalty
    end

    # Returns true if +penalty+ does not return true.
    def no_penalty?
      !@penalty
    end

    # Checks if this MatchLogic object is true for a given Query +qry+
    def is_true?(qry)
      predicate.call(qry) ? true : false
    end

    # Kickback function, executes when this MatchLogic succeeds.
    def on_succeed; end

    # Kickback function, executes when this MatchLogic fails.
    def on_failure; end
  end

  # The various types of MatchLogic objects are stored here.
  module MatchLogicTypes
    include Enumerable
    # Any created descendants are stored here.
    @@members = []

    # Yields the +members+ array
    def self.all
      @@members
    end

    # Yields each of the elements of the +members+ array to the block +blk+
    def self.each(&blk)
      @@members.each(&blk)
    end

    # Counts the number of MatchLogic subclasses.
    def self.count
      @@members.count
    end

    # Counts the number of MatchLogic subclasses, excluding those which
    # don't count against the match result if failed
    def self.count_nopenalty
      @@members.select(&:no_penalty?)
    end

    # Yields all of the different #priority keys used by all MatchLogic subclasses.
    def self.priorities
      @@members.map { |m| m.new(nil).priority }
    end

    # Searches +members+ for an element whose +priority+ matches +srch+
    def self.[](srch)
      @@members.find { |m| m.new(nil).priority == srch }
    end

    def self.<<(input)
      @@members << input if input <= DismalTony::MatchLogic
    end

    # Used for necessary presence detection. Raises a MatchLogicFailure error if it fails.
    # Keyword and priority is "must"
    class MustBe < MatchLogic
      def initialize(pre) # :nodoc:
        super(pre)
        @priority = :must
      end

      # raises a MatchLogicFailure.
      def on_failure
        raise MatchLogicFailure
      end
    end

    # Used for optimal presence detection. Logic criteria using the "should" method are counted for penalties,
    # but don't result in failure if unmatched.
    class ShouldBe < MatchLogic
      def initialize(pre) # :nodoc:
        super(pre)
        @priority = :should
      end
    end

    # Used for possible presence detection. Logic criteria using the "could" method aren't counted for penalties, but
    # do increase certainty scores.
    class CouldBe < MatchLogic
      def initialize(pre) # :nodoc:
        super(pre)
        @priority = :could
        @penalty = false
      end
    end

    # The "keyword" method is used for criteria which represent obvious clues that a Directive should be employed.
    # Covers obvious named domain entities, and unambiguous verbs / symbols. Increases the certainty factor by 5x base,
    # but does raise a MatchLogicFailure if not matched.
    class IsKeyword < MatchLogic
      def initialize(pre) # :nodoc:
        super(pre)
        @priority = :keyword
        @success_incr = 5
      end

      def on_failure
        raise MatchLogicFailure
      end
    end

    # Inverse of MustBe. Raises an error if it succeeds, and increments the certainty by 1 in the case where it fails.
    class DoesNot < MatchLogic
      def initialize(pre) # :nodoc:
        super(pre)
        @priority = :doesnt
        @succeeds_incr = 0
        @fails_incr = 1
      end

      # Raises a MatchLogicFailure if this matches.
      def on_succeed
        raise MatchLogicFailure
      end
    end
  end
end
