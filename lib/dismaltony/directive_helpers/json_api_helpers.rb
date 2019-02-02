module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
    # Mixin for JSON-based web APIs.
    module JSONAPIHelpers
      include HelperTemplate

      # Mixin for JSON-based web APIs.
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Takes in a block +blk+ and calculates it later to ensure late ENV access
        def set_api_defaults(&blk)
          @api_defaults_proc = blk
        end

        # Retrieves the block from #set_api_defaults and calls it.
        def get_api_defaults
          res = {}
          @api_defaults_proc.call(res)
          res
        end

        # Gets the api_defaults
        def api_defaults
          @api_defaults ||= get_api_defaults
        end

        # Sets the api_defaults
        def api_defaults=(newval)
          @api_defaults = newval
        end

        # Gets the api_url
        def api_url
          @api_url
        end

        # Sets the api_url
        def api_url=(newval)
          @api_url = newval
        end

        # DSL method for setting the api_url
        def set_api_url(url)
          @api_url = url
        end
      end

      # Mixin for JSON-based web APIs.
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Instance hook for the api_url
        def api_url
          @api_url ||= self.class.api_url
          @api_url
        end

        # Sets the api_url
        def api_url=(new_value)
          @api_url = new_value
        end

        # Generates an API request from the provided data to this mixin.
        # Parses and returns the JSON body of a request, intelligently merging
        # given arguments in +input_args+ and the #api_defaults
        def api_request(input_args)
          addr = URI(api_url)
          parms = input_args.clone
          parms = api_defaults.merge(parms)
          addr.query = URI.encode_www_form(parms)
          JSON.parse(Net::HTTP.get(addr))
        end

        # Instance hook for api_defaults
        def api_defaults
          @api_defaults ||= self.class.api_defaults
          @api_defaults
        end

        # Sets api_defaults
        def api_defaults=(new_value)
          @api_defaults = new_value
        end
      end
    end
  end
end
