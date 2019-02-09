require 'aws-sdk'

module DismalTony
  module ParsingStrategies
    class ComprehendStrategy < ParsingStrategy
      def self.call(q)
        ComprehendTopicMap.new(fetch_entities(q), fetch_key_phrases(q))
      end

      def self.aws_client
        @@aws_client ||= Aws::Comprehend::Client.new
      end

      def self.fetch_entities(q)
        qr = { language_code: 'en', text_list: [q] }
        aws_client.batch_detect_entities(qr)
                  .result_list
                  .first
                  .entities
                  .map { |a| ComprehendTopicEntity.new(a) }
      end

      def self.fetch_key_phrases(q)
        qr = { language_code: 'en', text_list: [q] }
        aws_client.batch_detect_key_phrases(qr)
                  .result_list
                  .first
                  .key_phrases
                  .map { |a| ComprehendTopicKeyPhrase.new(a) }
      end
    end

    # Represents a capture entity from the AWS Comprehend api
    class ComprehendTopicEntity
      # The text content recognized
      attr_reader :text
      # The entity type, one of ENTITY_TYPES
      attr_reader :type
      # The confidence score from the Comprehend API
      attr_reader :score
      # A range object denoting the subset of the utterance containing the entity
      attr_reader :document_location

      # All possible entity types, for easy checking
      ENTITY_TYPES = %i[
        commercial_item
        date
        event
        location
        organization
        other
        person
        quantity
        title
      ].freeze


      # Takes in the Comprehend API's Entity type +awse+
      def initialize(awse)
        @type = awse.type.downcase.to_sym
        @text = awse.text
        @score = awse.score
        @document_location = awse.begin_offset..awse.end_offset
      end

      # The text content
      def to_s
        text
      end

      # The score
      def to_f
        score
      end

      def match?(txt)
        text.match?(txt)
      end

      def match(txt)
        text.match(txt)
      end

      alias =~ match
    end

    # A Key phrase, a noun phrase detected by the AWS Comprehend api to be
    # important to the Query's meaning.
    class ComprehendTopicKeyPhrase
      # The text content recognized
      attr_reader :text
      # Confidence interval that this is a key phrase
      attr_reader :score
      # A range object denoting the subset of the utterance containing the key phrase
      attr_reader :document_location

      # Takes in the Comprehend API's Key Phrase type +awskp+
      def initialize(awskp)
        @text = awskp.text
        @score = awskp.score
        @document_location = awskp.begin_offset..awskp.end_offset
      end

      # The text content
      def to_s
        text
      end

      # The score
      def to_f
        score
      end

      def match?(txt)
        text.match?(txt)
      end

      def match(txt)
        text.match(txt)
      end

      alias =~ match
    end

    # A collection of topic detection information from the AWS Comprehend api
    class ComprehendTopicMap
      # A collection of ComprehendTopicEntity objects
      attr_reader :entities
      # A collection of ComprehendTopicKeyPhrase objects
      attr_reader :key_phrases

      # Takes in entities +es+ and key_phrases +ks+
      def initialize(es, ks)
        @entities = es
        @key_phrases = ks
      end

      DismalTony::ParsingStrategies::ComprehendTopicEntity::ENTITY_TYPES.each do |label|
        l = case label
            when :person
              :people
            when :quantity
              :quantities
            else
              (label.to_s << 's').to_sym
            end
        define_method(l) do
          entities.select { |j| j.type == label }
        end

        define_method(label) do
          entities.select { |j| j.type == label }.first
        end

        define_method((label.to_s << '?').to_sym) do
          entities.select { |j| j.type == label }.any?
        end

      end

      # True if both subsets are empty
      def empty?
        entities.empty? && key_phrases.empty?
      end
    end
  end
end
