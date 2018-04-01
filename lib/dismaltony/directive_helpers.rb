require 'json'
require 'net/http'
require 'open-uri'
require 'uri'
require 'ostruct'

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
        def add_synonyms(&blk)
          new_syns = {}
          yield new_syns
          @synonyms.merge!(new_syns)
        end

        def synonyms
          @synonyms ||= {
            /^awesome$/i => %w[great excellent cool awesome splendid],
            /^okay$/i => %w[okay great alright],
            /^hello$/i => %w[hello hi greetings],
            /^yes$/i => %w[yes affirmative definitely correct certainly],
            /^no$/i => %w[no negative incorrect false],
            /^update$/i => %w[updated changed modified revised altered edited adjusted],
            /^updated$/i => %w[update change modify revise alter edit adjust],
            /^add$/i => %w[added created],
            /^added$/i => %w[add create]
          }
        end
      end

      module InstanceMethods
        def random_emoji(*moj)
          if moj.length.zero?
            DismalTony::EmojiDictionary.emoji_table.keys.sample
          else
            moj.sample
          end
        end

        def synonym_for(word)
          resp = nil
          synonyms.each do |reg, syns|
            resp = word =~ reg ? syns.sample : nil
            return resp if resp
          end
          word
        end

        def synonyms
          @synonyms ||= self.class.synonyms
          @synonyms
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

    # Provides simpler access to DataStore#directive_data, and streamlines
    # defining and creating structs to put in it.
    module StoreAndRetrieveHelpers
      include HelperTemplate
      module ClassMethods
        def define_data_struct(&blk)
          @data_struct_template = blk.call
        end

        def data_struct_template
          @data_struct_template
        end

        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end

      module InstanceMethods
        def get_stored_data(*ky)
          self.vi.data_store.directive_data.fetch(self.name, *ky)
        end

        def store_data(ky, v=nil, &block)
          if block_given?
            self.vi.data_store.store_data(directive: self.name, key: ky, value: data_struct(&block))
          else
            self.vi.data_store.store_data(directive: self.name, key: ky, value: v)
          end
        end

        def data_struct(&blk)
          ud_args = {}
          yield ud_args
          if data_struct_template.nil?
            OpenStruct.new(ud_args)
          else
            args_list = data_struct_template.members.map { |a| ud_args[a] }
            data_struct_template.new(*args_list)
          end
        end

        def data_struct_template
          @data_struct_template ||= self.class.data_struct_template
          @data_struct_template
        end

        def data_struct_template=(newval)
          @data_struct_template = newval
        end
      end
    end
  end
end