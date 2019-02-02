module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
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
            resp = word&.match?(reg) ? syns.sample : nil
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
  end
end
