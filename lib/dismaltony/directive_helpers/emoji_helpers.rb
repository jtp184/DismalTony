module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
    # Assists with emoji selection
    module EmojiHelpers
      include HelperTemplate

      # Assists with emoji selection
      # Contains the Instance methods of the helper, which are added on inclusion
      module InstanceMethods
        # Chooses randomly from +moj+, or if no arguments are passed randomly from all emoji.
        def random_emoji(*moj)
          if moj.length.zero?
            DismalTony::Formatter.emoji_dictionary.keys.sample
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
  end
end
