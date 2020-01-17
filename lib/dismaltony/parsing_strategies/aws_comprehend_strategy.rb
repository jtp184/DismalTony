require 'aws-sdk'

module DismalTony #:nodoc:
  module ParsingStrategies #:nodoc:
    # For use with AWS Comprehend, attempts to collect known entities as topics
    class ComprehendTopicStrategy < ParsingStrategy
      # Runs .fetch_entities for the query +q+ and creates a new ComprehendTopicMap
      def self.call(q)
        ComprehendTopicMap.new(fetch_entities(q))
      end

      def self.value_class #:nodoc:
        ComprehendTopicMap
      end

      # An Aws::Comprehend::Client instance
      def self.aws_client
        @aws_client ||= Aws::Comprehend::Client.new
      end

      # For the entities in Query +q+, detects entities 
      # and creates a new ComprehendTopicEntity for each
      def self.fetch_entities(q)
        qr = { language_code: 'en', text: q }
        aws_client.detect_entities(qr).entities
                  .map { |a| ComprehendTopicEntity.new(a) }
      end
    end

    # For use with AWS Comprehend, detects key phrases
    class ComprehendKeyPhraseStrategy < ParsingStrategy
      # Takes in a query +q+ and makes a new ComprehendKeyPhraseMap out of .fetch_key_phrases
      def self.call(q)
        ComprehendKeyPhraseMap.new(fetch_key_phrases(q))
      end

      def self.value_class #:nodoc:
        ComprehendKeyPhraseMap
      end

      # An Aws::Comprehend::Client instance
      def self.aws_client
        @aws_client ||= Aws::Comprehend::Client.new
      end

      # Takes in a query +q+ and detects key phrases, maps them each to
      # a ComprehendTopicKeyPhrase
      def self.fetch_key_phrases(q)
        qr = { language_code: 'en', text: q }
        aws_client.detect_key_phrases(qr).key_phrases
                  .map { |a| ComprehendTopicKeyPhrase.new(a) }
      end
    end

    # For use with AWS Comprehend, detects syntax and part of speech data
    class ComprehendSyntaxStrategy < ParsingStrategy
      # Takes in a query +q+ and makes a new ComprehendSyntaxMap out of .fetch_syntax_labels
      def self.call(q)
        ComprehendSyntaxMap.new(fetch_syntax_labels(q))
      end

      def self.value_class #:nodoc:
        ComprehendSyntaxMap
      end

      # An Aws::Comprehend::Client instance
      def self.aws_client
        @aws_client ||= Aws::Comprehend::Client.new
      end

      # Takes in a query +q+ and detects utterance tokens, maps them each to
      # a ComprehendSpeechTag 
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

      # Passes the match? to +text+
      def match?(txt)
        text.match?(txt)
      end

      # Passes the match to +text+
      def match(txt)
        text.match(txt)
      end

      alias =~ match

      # Compares document_location of +other+
      def same_token?(other)
        other.document_location == document_location
      rescue NoMethodError
        nil
      end
    end

    # A collection of topic detection information from the AWS Comprehend api
    class ComprehendTopicMap
      # A collection of ComprehendTopicEntity objects
      attr_reader :entities

      # Takes in entities +es+ and stores them.
      def initialize(es)
        @entities = es
      end

      # For each of the labels...
      DismalTony::ParsingStrategies::ComprehendTopicEntity::ENTITY_TYPES.each do |label|
        # Create a singular version
        sing = case label
               when :other
                 :other_entity
               else
                 label
        end

        # Create a pluralized version
        plur = case sing
               when :person
                 :people
               when :quantity
                 :quantities
               when :other_entity
                 :other_entities
               else
                 (sing.to_s << 's').to_sym
        end

        # Finds all entities whose type is equal to the label +plur+
        define_method(plur) do
          r = entities.find_all { |j| j.type == label }
        end

        # Finds the first entity whose type is equal to the label +sing+
        define_method(sing) do
          entities.find { |j| j.type == label }
        end

        # Returns true if any entities are of type +sing+
        define_method((sing.to_s << '?').to_sym) do
          entities.any? { |j| j.type == label }
        end

        # Returns true if there are multiple entities of type +plur+
        define_method((plur.to_s << '?').to_sym) do
          r = entities.select { |j| j.type == label }
          r.count > 0
        end
      end

      # True if both subsets are empty
      def empty?
        entities.empty?
      end
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

      # Passes the match? to +text+
      def match?(txt)
        text.match?(txt)
      end

      # Passes the match to +text+
      def match(txt)
        text.match(txt)
      end

      alias =~ match

      # Compares document_location of +other+
      def same_token?(other)
        other.document_location == document_location
      rescue NoMethodError
        nil
      end
    end

    # A Collection of key phrases
    class ComprehendKeyPhraseMap
      # A collection of ComprehendTopicKeyPhrase objects
      attr_reader :key_phrases

      # Takes in key phrases +ks+ and stores them.
      def initialize(ks)
        @key_phrases = ks
      end

      # Gives the first found key phrase as a shortcut
      def key_phrase
        key_phrases.first
      end
    end

    # A Single utterance token, tagged with a part of speech and certainty
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
      ].freeze

      # Human-friendly labels for each tag
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
      ].freeze

      # Builds from the +awse+ entity returned by the API
      def initialize(awse)
        @text = awse.text
        @score = awse.part_of_speech.score
        @tag = awse.part_of_speech.tag.downcase.to_sym
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

      # Passes the match? to +text+
      def match?(txt)
        text.match?(txt)
      end

      # Passes the match to +text+
      def match(txt)
        text.match(txt)
      end

      # Checks if any of the supplied +various+ regexes match
      def any_of?(*various)
        various.any? { |a| a.match?(text) }
      end

      # Compares document_location of +other+
      def same_token?(other)
        other.document_location == document_location
      rescue NoMethodError
        nil
      end
    end

    # A Part-of-speech tag index for the query.
    class ComprehendSyntaxMap
      # A collection of ComprehendSpeechTag objects
      attr_reader :pos_tags

      # Tages in tags and sets +pos_tags+ to it
      def initialize(tgs)
        @pos_tags = tgs
      end

      # For each of the POS_LABELS...
      DismalTony::ParsingStrategies::ComprehendSpeechTag::POS_LABELS.each_with_index do |label, ix|
        # Create a plural
        plur = case label
               when :auxiliary
                 :auxiliaries
               else
                 (label.to_s << 's').to_sym
        end

        # Create a question form
        ques = (label.to_s << '?').to_sym
        # Create a plural question form
        plur_ques = (plur.to_s << '?').to_sym

        # Gets the corresponding tag
        the_tag = DismalTony::ParsingStrategies::ComprehendSpeechTag::POS_TAGS[ix]

        # For +label+, gets the tags which match the tag
        define_method(label) do
          pos_tags.find { |t| t.tag == the_tag }
        end

        # For +plur+, gets all tags which match the tag
        define_method(plur) do
          pos_tags.find_all { |t| t.tag == the_tag }
        end

        # For +ques+ returns true if any tags exist for the tag
        define_method(ques) do
          pos_tags.any? { |t| t.tag == the_tag }
        end

        # For +plur_ques+ returns true if more than one tag exists for the tag
        define_method(plur_ques) do
          r = pos_tags.find_all? { |t| t.tag == the_tag }
          r.count > 1
        end
      end

      # Returns true if any pattern in +pattns+ matches the tags
      def contains?(*pattns)
        pattns.any? do |pattn|
          pos_tags.any? { |wor| wor.text =~ pattn }
        end
      end
    end
  end
end
