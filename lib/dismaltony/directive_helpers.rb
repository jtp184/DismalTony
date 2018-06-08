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

    # Utility functions to help construct responses easier.
    module ConversationHelpers
      include HelperTemplate

      # Utility functions to help construct responses easier.
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Takes in Hash<Regexp, Array<String>> and adds them to the synonyms
        def add_synonyms # :yields: synonyms
          new_syns = {}
          yield new_syns
          synonyms.merge!(new_syns)
        end

        # The array of synonyms available for using #synonym_for
        def synonyms
          @synonyms ||= {
            /^awesome$/i => %w[great excellent cool awesome splendid],
            /^okay$/i => %w[okay great alright],
            /^hello$/i => %w[hello hi greetings],
            /^yes$/i => %w[yes affirmative definitely correct certainly],
            /^no$/i => %w[no negative incorrect false],
            /^update$/i => %w[update change modify revise alter edit adjust],
            /^updated$/i => %w[updated changed modified revised altered edited adjusted],
            /^add$/i => %w[add create],
            /^added$/i => %w[added created],
            /^what|how$/i => %w[how what]
          }
        end
      end

      # Utility functions to help construct responses easier.
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Given a string, scans through the synonym array for any potential synonyms.
        def synonym_for(word)
          resp = nil
          synonyms.each do |reg, syns|
            resp = word =~ reg ? syns.sample : nil
            return resp if resp
          end
          word
        end

        # Instance hook for the class method
        def synonyms
          @synonyms ||= self.class.synonyms
          @synonyms
        end
      end
    end

    # Assists with emoji selection
    module EmojiHelpers
      include HelperTemplate

      # Assists with emoji selection
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Chooses randomly from +moj+, or if no arguments are passed randomly from all emoji.
        def random_emoji(*moj)
          if moj.length.zero?
            DismalTony::EmojiDictionary.emoji_table.keys.sample
          else
            moj.sample
          end
        end

        # Returns randomly from a predefined set of positiveemoji
        def positive_emoji
          %w[100 checkbox star thumbsup rocket].sample
        end

        # Returns randomly from a predefined set of negative emoji
        def negative_emoji
          %w[cancel caution frown thumbsdown siren].sample
        end

        # Returns randomly from a predefined set of face emoji
        def random_face_emoji
          %w[cool goofy monocle sly smile think].sample
        end

        # Returns randomly from a predefined set of time emoji
        def time_emoji
          %w[clockface hourglass alarmclock stopwatch watch].sample
        end
      end
    end

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

    # Provides simpler access to DataStore#directive_data, and streamlines
    # defining and creating structs to put in it.
    module DataStructHelpers
      include HelperTemplate

      # Provides simpler access to DataStore#directive_data, and streamlines
      # defining and creating structs to put in it.
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Takes in a block returning a Struct, where user schema is defined.
        def define_data_struct
          @data_struct_template = yield
        end

        # Gets data_struct_template
        def data_struct_template
          @data_struct_template
        end

        # Sets data_struct_template
        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end

      # Provides simpler access to DataStore#directive_data, and streamlines
      # defining and creating structs to put in it.
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Uses the Directive's name, and any passed values to dig into the directive data
        def get_stored_data(*ky)
          vi.data_store.read_data(name, *ky)
        end

        # In this Directive's storage, stores +ky+ with a value of +v+.
        # If a block is given, passes it to #data_struct and uses that as the value.
        def store_data(ky, v = nil, &block)
          if block_given?
            vi.data_store.store_data(directive: name, key: ky, value: data_struct(&block))
          else
            vi.data_store.store_data(directive: name, key: ky, value: v)
          end
        end

        # Takes in arguments to create a new struct. If no #data_struct_template is defined,
        # It creates an OpenStruct instead. Otherwise, correctly maps values to the struct.
        def data_struct # :yields: arguments
          ud_args = {}
          yield ud_args
          if data_struct_template.nil?
            OpenStruct.new(ud_args)
          else
            args_list = data_struct_template.members.map { |a| ud_args[a] }
            data_struct_template.new(*args_list)
          end
        end

        # Instance hook for the data struct template
        def data_struct_template
          @data_struct_template ||= self.class.data_struct_template
          @data_struct_template
        end

        # Sets the data struct template
        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end
    end

    # Provides a mechanism to return rich values from responses
    module DataRepresentationHelpers
      include HelperTemplate

      # Provides a mechanism to return rich values from responses
      # Contains the Class methods of the helper, which are added on inclusion
      module ClassMethods
        # Defines a default data representation
        def define_data_representation
          @data_representation = yield
        end

        # Gets data_representation
        def data_representation
          @data_representation
        end

        # Sets data_representation to +new_val+
        def data_representation=(new_val)
          @data_representation = new_val
        end
      end

      # Provides a mechanism to return rich values from responses
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Instance hook for data_representation
        def data_representation
          @data_representation ||= self.class.data_representation
          @data_representation ||= parameters
          @data_representation ||= OpenStruct.new
          @data_representation
        end

        # Sets data_representation to +new_val+
        def data_representation=(new_val)
          @data_representation = new_val
        end

        # DSL method, overwrites data representation
        def return_data(data)
          @data_representation = data
        end
      end
    end
  end
end
