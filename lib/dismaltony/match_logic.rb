module DismalTony
	class MatchLogic
		@@members = []

		def self.all
			@@members
		end

		def self.each(&blk)
			@@members.each(&blk)
		end

		def self.count
			@@members.count
		end

		def self.count_nopenalty
			@@members.select(&:no_penalty?)
		end

		def self.inherited(subclass)
			@@members << subclass
		end

		def self.priorities
			@@members.map { |m| m.new(nil).priority }
		end

		def self.[](srch)
			@@members.find { |m| m.new(nil).priority == srch }
		end
	end

	class MatchLogic
		attr_accessor :priority
		attr_accessor :predicate

		def initialize(pre)
			@predicate = pre
			@priority = :matches
			@succeeds_incr = 1
			@fails_incr = 0
			@penalty = true
		end

		def +(other)
			@succeeds_incr + other
		end

		def coerce(other)
			[other, @succeeds_incr.to_f]
		end

		def fail
			@fails_incr
		end

		def penalty?
			@penalty
		end

		def no_penalty?
			!@penalty
		end

		def is_true?(qry)
			predicate.(qry) ? true : false
		end

		def on_succeed; end

		def on_failure; end
	end

	module MatchLogicTypes
		class MustBe < MatchLogic
			def initialize(pre)
				super(pre)
				@priority = :must
			end

			def on_failure
				raise MatchLogicFailure
			end
		end

		class ShouldBe < MatchLogic
			def initialize(pre)
				super(pre)
				@priority = :should
			end
		end

		class CouldBe < MatchLogic
			def initialize(pre)
				super(pre)
				@priority = :could
				@penalty = false
			end
			def on_failure
				nil
			end
		end

		class IsKeyword < MatchLogic
			def initialize(pre)
				super(pre)
				@priority = :keyword
				@success_incr = 5
			end
			def on_failure
				raise MatchLogicFailure
			end
		end

		class DoesNot < MatchLogic
			def initialize(pre)
				super(pre)
				@priority = :doesnt
				@succeeds_incr = 0
				@fails_incr = 1
			end

			def on_succeed
				raise MatchLogicFailure
			end
		end
	end
end