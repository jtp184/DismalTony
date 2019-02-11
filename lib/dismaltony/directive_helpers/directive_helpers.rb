require 'json'
require 'net/http'
require 'open-uri'
require 'uri'
require 'ostruct'

module DismalTony # :nodoc:
  # Umbrella module for all mixins for Directives
  module DirectiveHelpers
    # Basic template , adds the inheritence methods through metaprogramming so
    # that n-children inherit class methods and instance methods apropriately.
    module HelperTemplate
      # Special case, only includes the class methods here.
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Adds the inclusion method to the class this class is included on,
        # So that its n-children inherit class methods
        def included(base)
          base.send(:include, const_get(:InstanceMethods))
          base.extend const_get(:ClassMethods)
        end
      end
    end

    # Basic helpers that make the Directives function
    module CoreHelpers
      include HelperTemplate

      # Basic helpers that make the Directives function
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # DSL function, sets the Directives +name+ to +param+
        def set_name(param)
          @name = param
        end

        # DSL function, sets the Directives +group+ to +param+
        def set_group(param)
          @group = param
        end

        # DSL function, adds a new entry to the +parameters+ hash keyed by +param+ and given a value of +initial+.
        def frag_default(**these)

          @default_frags ||= {}
          @default_frags.merge(these)
        end

        # DSL function, takes in +these+ fragments, either as an Array or Hash, and
        # adds them to the defaults
        def expect_frags(*these)
          @default_frags ||= {}
          these = these.first if these.one? && these.first.is_a?(Hash)

          case these
          when Array
            these.each { |a| @default_frags[a.to_sym] = nil }
          when Hash
            these.each_pair { |a, b| @default_frags[a.to_sym] = b }
          end
        end

        # Yields the +criteria+ array, and uses the +block+ to add its results to
        # +match_criteria+ afterwards, allowing you to add new MatchLogic objects using the DSL.
        def add_criteria
          crit = []
          yield crit
          @match_criteria ||= []
          @match_criteria += crit
        end

        # This directive's parsing strategies
        def parsing_strategies
          @parsing_strategies ||= []
        end

        # Writer, sets +parsing_strategy+ to +ps+
        def parsing_strategies=(ps)
          @parsing_strategies = ps
        end

        # Sets the +parsing_strategies+ to +strats+
        def use_parsing_strategies # :yields: strats
          x = []
          yield x
          self.parsing_strategies = x
        end

        # Returns an Errored directive, using +qry+ and +vi+ to construct the new Directive
        def error(qry, vi)
          me = new(qry, vi)
          me.query.complete(self, HandledResponse.error)
        end
      end

      # Basic helpers that make the Directives function
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
      end
    end
  end
end
