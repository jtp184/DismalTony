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
        def add_param(param, initial = nil)
          @default_params ||= {}
          @default_params[param.to_sym] = initial
        end

        # DSL function, takes each key-value pair in +inputpar+ and adds a new entry to
        # the +parameters+ hash keyed by +param+ and given a value of +initial+.
        def add_params(inputpar)
          inputpar.each do |ki, va|
            @default_params[ki] = va
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
