require 'engtagger'

$tgr = EngTagger.new

@tags = %w[CC CD DET EX FW IN JJ JJR JJS LS MD NN NNP NNPS NNS PDT POS PRP PRPS RB RBR RBS RP SYM TO UH VB VBD VBG VBN VBP VBZ WDT WP WPS WRB PP PPC PPD PPL PPR PPS LRB RRB]
@pos = ['Conjunction, coordinating', 'Adjective, cardinal number', 'Determiner', 'Pronoun, existential there', 'Foreign words', 'Preposition / Conjunction', 'Adjective', 'Adjective, comparative', 'Adjective, superlative', 'Symbol, list item', 'Verb, modal', 'Noun', 'Noun, proper', 'Noun, proper, plural', 'Noun, plural', 'Determiner, prequalifier', 'Possessive', 'Determiner, possessive second', 'Determiner, possessive', 'Adverb', 'Adverb, comparative', 'Adverb, superlative', 'Adverb, particle', 'Symbol', 'Preposition', 'Interjection', 'Verb, infinitive', 'Verb, past tense', 'Verb, gerund', 'Verb, past/passive participle', 'Verb, base present form', 'Verb, present 3SG -s form', 'Determiner, question', 'Pronoun, question', 'Determiner, possessive & question', 'Adverb, question', 'Punctuation, sentence ender', 'Punctuation, comma', 'Punctuation, dollar sign', 'Punctuation, quotation mark left', 'Punctuation, quotation mark right', 'Punctuation, colon, semicolon, elipsis', 'Punctuation, left bracket', 'Punctuation, right bracket']
@colors = %w[g r y y n g r r r g b c c c c y y y y i i i i n g n b b b b b b u u u u n n n n n n n n]
@tags.map!(&:downcase)
@colors = Hash[@tags.zip(@colors)]
@tag_types = Hash[@tags.zip(@pos)]

class ActionDefinition
  attr_accessor :pattern

  def define_pattern
    return_string = 'Pattern: '
    pattern_tags = @pattern.split('/')

    pattern_tags.each do |atom|
      return_string += "#{@tag_types[atom]}(#{atom}) => "
    end

    return_string
  end

  def initialize(pt)
    @pattern = pt
    @tags = %w[CC CD DET EX FW IN JJ JJR JJS LS MD NN NNP NNPS NNS PDT POS PRP PRPS RB RBR RBS RP SYM TO UH VB VBD VBG VBN VBP VBZ WDT WP WPS WRB PP PPC PPD PPL PPR PPS LRB RRB]
    @tags.map!(&:downcase)
    @pos = ['Conjunction, coordinating', 'Adjective, cardinal number', 'Determiner', 'Pronoun, existential there', 'Foreign words', 'Preposition / Conjunction', 'Adjective', 'Adjective, comparative', 'Adjective, superlative', 'Symbol, list item', 'Verb, modal', 'Noun', 'Noun, proper', 'Noun, proper, plural', 'Noun, plural', 'Determiner, prequalifier', 'Possessive', 'Determiner, possessive second', 'Determiner, possessive', 'Adverb', 'Adverb, comparative', 'Adverb, superlative', 'Adverb, particle', 'Symbol', 'Preposition', 'Interjection', 'Verb, infinitive', 'Verb, past tense', 'Verb, gerund', 'Verb, past/passive participle', 'Verb, base present form', 'Verb, present 3SG -s form', 'Determiner, question', 'Pronoun, question', 'Determiner, possessive & question', 'Adverb, question', 'Punctuation, sentence ender', 'Punctuation, comma', 'Punctuation, dollar sign', 'Punctuation, quotation mark left', 'Punctuation, quotation mark right', 'Punctuation, colon, semicolon, elipsis', 'Punctuation, left bracket', 'Punctuation, right bracket']
    @tag_types = Hash[@tags.zip(@pos)]
  end

  def match(sentence)
    pattern_tags = @pattern.split('/')

    values = []

    tagged = tag sentence

    tagged.keys.each do |key|
      pattern_tags.each do |pattern, _pi|
        values << key if tagged[key] =~ Regexp.new(pattern)
      end
    end
    values
  end

  def tag_split(w)
    tag = (w.match /(<(\w+)>)/)[2]
    word = (w.match /((<\w+>)(.+)(<\/\w+>))/)[3]

    [word, tag]
  end

  def tag(sentence)
    tagged_sentence = {}
    marked = $tgr.add_tags sentence

    marked.split(' ').each do |word|
      split = tag_split word
      tagged_sentence[split[0]] = split[1]
    end

    tagged_sentence
  end
end

should_loop = true

zork = ActionDefinition.new('vb/n/')

puts print zork.match ''

# while(should_loop)
#   puts 'Enter a pattern:\n'
#   ptr_str = gets
#   ptr = ActionDefinition.new(ptr_str)
#   puts ptr.define_pattern
#   puts 'Enter a query: \n'
#   sentence = gets
#   puts (ptr.match sentence)
#   puts
# end
