require 'json'
require 'net/http'
require 'open-uri'
require 'uri'

module DismalTony # :nodoc:
  # Umbrella module for all mixins for Directives
  module DirectiveHelpers 
    # Basic template for a Helper, adds the
    # inheritence methods through metaprogramming 
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
        def set_name(param)
          @name = param
        end

        def set_group(param)
          @group = param
        end    

        def add_param(param, initial = nil)
          @default_params ||= {}
          @default_params[param.to_sym] = initial
        end

        def add_params(inputpar)
          inputpar.each do |ki, va|
            @default_params[ki] = va
          end
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
          c = {}
          yield c
          @api_defaults ||= {}
          @api_defaults.merge!(c)
        end
      end

      module InstanceMethods
        def api_url
          @api_url
        end

        def api_url=(new_value)
          @api_url = new_value
        end

        def api_request(input_args)
          addr = URI(@api_url)
          parms = input_args.clone
          parms = @api_defaults.merge(parms)
          addr.query = URI.encode_www_form(parms)
          JSON.parse(Net::HTTP.get(addr))
        end

        def api_defaults
          @api_defaults
        end

        def api_defaults=(new_value)
          @api_defaults = new_value
        end
      end
    end
  end
end