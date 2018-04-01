require 'json'
require 'net/http'
require 'open-uri'
require 'uri'

module DismalTony # :nodoc:
  # Umbrella module for all mixins for Directives
  module DirectiveHelpers 
    # Basic template , adds the inheritence methods 
    # through metaprogramming so that n-children inherit
    # class methods
    module HelperTemplate
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def included(base)
          base.send(:include, self.const_get(:InstanceMethods))
          base.extend self.const_get(:ClassMethods)
        end
      end
    end

    # Basic helpers that make the Directives function
    module CoreHelpers
      include HelperTemplate

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
        def add_criteria(&block)
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

      module InstanceMethods
        def params
          @parameters
        end
      end
    end

    # Utility functions to help construct responses easier.
    module ConversationHelpers
      include HelperTemplate

      module ClassMethods
      end

      module InstanceMethods
        def random_emoji(*moj)
          if moj.length.zero?
            DismalTony::EmojiDictionary.emoji_table.keys.sample
          else
            moj.sample
          end
        end
      end
    end

    # Mixin for JSON-based web APIs.
    module JSONAPIHelpers
      include HelperTemplate

      module ClassMethods
        def set_api_defaults(&blk)
          @api_defaults_proc = blk
        end

        def get_api_defaults
          res = {}
          @api_defaults_proc.call(res)
          res
        end

        def api_defaults
          @api_defaults ||= get_api_defaults
        end

        def api_defaults=(newval)
          @api_defaults = newval
        end

        def api_url
          @api_url
        end

        def api_url=(newval)
          @api_url = newval
        end

        def set_api_url(url)
          @api_url = url
        end
      end

      module InstanceMethods
        def api_url
          @api_url ||= self.class.api_url
          @api_url
        end

        def api_url=(new_value)
          @api_url = new_value
        end

        def api_request(input_args)
          addr = URI(api_url)
          parms = input_args.clone
          parms = api_defaults.merge(parms)
          addr.query = URI.encode_www_form(parms)
          JSON.parse(Net::HTTP.get(addr))
        end

        def api_defaults
          @api_defaults ||= self.class.api_defaults
          @api_defaults
        end

        def api_defaults=(new_value)
          @api_defaults = new_value
        end
      end
    end

    module StoreAndRetrieveHelpers
      module ClassMethods

      end

      module InstanceMethods
        def get_stored_data(ky)
          self.vi.data_store.directive_data[self][ky]
        end

        def store_data(ky, v)
          self.vi.data_store.store_data(directive: self, key: ky, value: v)
        end
      end
    end

  end
end