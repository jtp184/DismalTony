require 'ibm_watson'

module DismalTony
  module ParsingStrategies
    class WatsonToneStrategy < ParsingStrategy
      def self.call(q)
        qry = {
          utterances: [{ text: q }],
          content_language: 'en-US',
          accept_language: 'en-US'
        }

        full_text = watson.tone_chat(qry).result['utterances_tone']

        tn = full_text.first['tones'].map { |t| WatsonTone.detect(t['tone_id'].to_sym, t['score']) }
        tn << WatsonNeutralTone.new(score: 1.0) if tn.empty?
        WatsonToneMap.new(tn)
      end

      def self.value_class
        WatsonToneMap
      end

      def self.watson
        return @watson if @watson

        @watson = IBMWatson::ToneAnalyzerV3.new(version: Date.new(2019, 1, 1).strftime('%Y-%m-%d'))
        @watson.username = ENV['IBM_USERNAME']
        @watson.password = ENV['IBM_PASSWORD']
        @watson
      end
    end

    class WatsonToneMap
      # The collection of Tone objects
      attr_reader :tones

      # Takes in an array of tones +tns+
      def initialize(tns)
        @tones = Array(tns)
        end

      # Returns Tone#to_sym for all tones
      def tone_symbols
        tones.map(&:to_sym)
        end

      # Sorts tones by Tone#score and returns highest
      def primary_tone
        tones.max_by(&:score)
      end

      %i[sad frustrated satisfied excited polite impolite sympathetic neutral].each do |label|
        define_method((label.to_s << '?').to_sym) { tones.any? { |t| t.to_sym == label } }
      end
    end

    class WatsonTone
      # Confidence interval that this tone was present
      attr_reader :score
      # Name of the tone
      attr_reader :name

      # Requires +args+ to have a score, then interprets #name from its own
      # class name
      def initialize(args = {})
        @score = args.fetch(:score)
        @name = /Watson(\w+)Tone/.match(self.class.name)[1]
      end

      # Returns #name
      def to_s
        name
      end

      # Returns #score
      def to_f
        score
      end

      # Downcases the name and then symbolizes it
      def to_sym
        name.downcase.to_sym
      end

      # A builder function, takes in any symbol +mood+ and matches it with
      # the tones, passing in the +skore+ variable
      def self.detect(mood, skore)
        case mood
        when :sad
          WatsonSadTone.new(score: skore)
        when :frustrated
          WatsonFrustratedTone.new(score: skore)
        when :satisfied
          WatsonSatisfiedTone.new(score: skore)
        when :excited
          WatsonExcitedTone.new(score: skore)
        when :polite
          WatsonPoliteTone.new(score: skore)
        when :impolite
          WatsonImpoliteTone.new(score: skore)
        when :sympathetic
          WatsonSympatheticTone.new(score: skore)
        else
          WatsonNeutralTone.new(score: skore)
        end
      end
     end

    # Indicates presence of Sadness in the Query.
    class WatsonSadTone < WatsonTone
    end

    # Indicates presence of Frustratedness in the Query.
    class WatsonFrustratedTone < WatsonTone
    end

    # Indicates presence of Satisfiedness in the Query.
    class WatsonSatisfiedTone < WatsonTone
    end

    # Indicates presence of Excitedness in the Query.
    class WatsonExcitedTone < WatsonTone
    end

    # Indicates presence of Politeness in the Query.
    class WatsonPoliteTone < WatsonTone
    end

    # Indicates presence of Impoliteness in the Query.
    class WatsonImpoliteTone < WatsonTone
    end

    # Indicates presence of Sympatheticness in the Query.
    class WatsonSympatheticTone < WatsonTone
    end

    # Indicates presence of Neutralness in the Query.
    class WatsonNeutralTone < WatsonTone
    end
  end
end
