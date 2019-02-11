require 'aws-sdk'

module DismalTony
  module ParsingStrategies
    class ComprehendTopicStrategy < ParsingStrategy
      def self.call(q)
        ComprehendTopicMap.new(fetch_entities(q), fetch_key_phrases(q))
      end

      def self.value_class
        ComprehendTopicMap
      end

      def self.aws_client
        @aws_client ||= Aws::Comprehend::Client.new
      end

      def self.fetch_entities(q)
        qr = { language_code: 'en', text: q }
        aws_client.detect_entities(qr).entities
        .map { |a| ComprehendTopicEntity.new(a) }
      end

      def self.fetch_key_phrases(q)
        qr = { language_code: 'en', text: q }
        aws_client.detect_key_phrases(qr).key_phrases
        .map { |a| ComprehendTopicKeyPhrase.new(a) }
      end
    end

    class ComprehendSyntaxStrategy < ParsingStrategy
      def self.call(q)
        ComprehendSyntaxMap.new(fetch_syntax_labels(q))
      end

      def self.value_class
        ComprehendSyntaxMap
      end

      def self.aws_client
        @aws_client ||= Aws::Comprehend::Client.new
      end

      def self.fetch_syntax_labels(q)
        qr = { language_code: 'en', text: q }
        aws_client.detect_syntax(qr).syntax_tokens
        .map { |a| ComprehendSpeechTag.new(a) }
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

    class ComprehendSpeechTag
      # The text content recognized
      attr_reader :text
      # The entity type, one of POS_TAGS
      attr_reader :tag
      # The confidence score from the Comprehend API
      attr_reader :score
      # A range object denoting the subset of the utterance containing the entity
      attr_reader :document_location

      # The 17 POS tags that AWS recognizes
      POS_TAGS = %i[
        adj
        adp
        adv
        aux
        cconj
        det
        intj
        noun
        num
        o
        part
        pron
        propn
        punct
        sconj
        sym
        verb
      ]

      POS_LABELS = %i[
        adjective
        adposition
        adverb
        auxiliary
        coordinating
        determiner
        interjection
        noun
        numeral
        other
        particle
        pronoun
        proper
        punctuation
        subordinating
        symbol
        verb
      ]

      # Builds from the +awse+ entity returned by the API
      def initialize(awse)
        @text = awse.text
        @score = awse.part_of_speech.score
        @tag = awse.part_of_speech.tag.downcase.to_sym
        @document_location = awse.begin_offset..awse.end_offset
      end
    end

    # A Part-of-speech tag index for the query.
    class ComprehendSyntaxMap
      # A collection of ComprehendSpeechTag objects
      attr_reader :pos_tags

      def initialize(tgs)
        @pos_tags = tgs
      end

      DismalTony::ParsingStrategies::ComprehendSpeechTag::POS_LABELS.each_with_index do |label,ix|
        plur = case label
        when :auxiliary
          :auxiliaries
        else
          (label.to_s << 's').to_sym
        end
        
        ques = (label.to_s << '?').to_sym
        plur_ques = (plur.to_s << '?').to_sym

        the_tag = DismalTony::ParsingStrategies::ComprehendSpeechTag::POS_TAGS[ix]

        define_method(label) do
          pos_tags.find { |t| t.tag == the_tag }
        end

        define_method(plur) do
          pos_tags.find_all { |t| t.tag == the_tag }
        end

        define_method(ques) do
          pos_tags.any? { |t| t.tag == the_tag }
        end

        define_method(plur_ques) do
          pos_tags.any? { |t| t.tag == the_tag }
        end
      end

      def contains?(*pattns)
        pattns.any? do |pattn|
          pos_tags.any? { |wor| wor.text =~ pattn }
        end
      end
    end
  end
end
