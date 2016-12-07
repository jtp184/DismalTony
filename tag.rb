require 'engtagger'

class String
	def black;          "\e[30m#{self}\e[0m" end
	def red;            "\e[31m#{self}\e[0m" end
	def green;          "\e[32m#{self}\e[0m" end
	def brown;          "\e[33m#{self}\e[0m" end
	def blue;           "\e[34m#{self}\e[0m" end
	def magenta;        "\e[35m#{self}\e[0m" end
	def cyan;           "\e[36m#{self}\e[0m" end
	def gray;           "\e[37m#{self}\e[0m" end

	def bg_black;       "\e[40m#{self}\e[0m" end
	def bg_red;         "\e[41m#{self}\e[0m" end
	def bg_green;       "\e[42m#{self}\e[0m" end
	def bg_brown;       "\e[43m#{self}\e[0m" end
	def bg_blue;        "\e[44m#{self}\e[0m" end
	def bg_magenta;     "\e[45m#{self}\e[0m" end
	def bg_cyan;        "\e[46m#{self}\e[0m" end
	def bg_gray;        "\e[47m#{self}\e[0m" end

	def bold;           "\e[1m#{self}\e[22m" end
	def italic;         "\e[3m#{self}\e[23m" end
	def underline;      "\e[4m#{self}\e[24m" end
	def blink;          "\e[5m#{self}\e[25m" end
	def reverse_color;  "\e[7m#{self}\e[27m" end
end

@tgr = EngTagger.new

@tags = %w(CC CD DET EX FW IN JJ JJR JJS LS MD NN NNP NNPS NNS PDT POS PRP PRPS RB RBR RBS RP SYM TO UH VB VBD VBG VBN VBP VBZ WDT WP WPS WRB PP PPC PPD PPL PPR PPS LRB RRB)
@pos = ["Conjunction, coordinating","Adjective, cardinal number","Determiner","Pronoun, existential there","Foreign words","Preposition / Conjunction","Adjective","Adjective, comparative","Adjective, superlative","Symbol, list item","Verb, modal","Noun","Noun, proper","Noun, proper, plural","Noun, plural","Determiner, prequalifier","Possessive","Determiner, possessive second","Determiner, possessive","Adverb","Adverb, comparative","Adverb, superlative","Adverb, particle","Symbol","Preposition","Interjection","Verb, infinitive","Verb, past tense","Verb, gerund","Verb, past/passive participle","Verb, base present form","Verb, present 3SG -s form","Determiner, question","Pronoun, question","Determiner, possessive & question","Adverb, question","Punctuation, sentence ender","Punctuation, comma","Punctuation, dollar sign","Punctuation, quotation mark left","Punctuation, quotation mark right","Punctuation, colon, semicolon, elipsis","Punctuation, left bracket","Punctuation, right bracket"]
@colors = %w(g r y y n g r r r g b c c c c y y y y i i i i n g n b b b b b b u u u u n n n n n n n n)
@tags.map! {|str| str.downcase}
@colors = Hash[@tags.zip(@colors)]
@tag_types = Hash[@tags.zip(@pos)]

def color_word w
	tag = (w.match (/(<(\w+)>)/))[2]
	word = (w.match (/((<\w+>)(.+)(<\/\w+>))/))[3]
	color = @colors[tag]
	if @tag_types[tag] =~ /Punctuation/
	else
		word = " #{word}"
	end
	case color
	when "g"
		return word.green
	when "r"
		return word.red
	when "y"
		return word.brown
	when "n"
		return word
	when "b"
		return word.blue
	when "c"
		return word.cyan
	when "i"
		return word.italic
	when "u"
		return word.underline
	else
		return word
	end
end

def tag sentence
	tagged_sentence = ""
	marked = @tgr.add_tags sentence

	marked.split(' ').each do |word|
		tagged_sentence << (color_word word)
	end

	return tagged_sentence
end

def analyze sentence
	tags = []
	marked = @tgr.add_tags sentence

	marked.split(' ').each do |word|
		tag = (word.match (/(<(\w+)>)/))[2]
		color = @colors[tag]
		tag = @tag_types[tag]
		colorized_tag = ""
		case color
		when "g"
			colorized_tag= tag.green
		when "r"
			colorized_tag= tag.red
		when "y"
			colorized_tag= tag.brown
		when "n"
			colorized_tag= tag
		when "b"
			colorized_tag= tag.blue
		when "c"
			colorized_tag= tag.cyan
		when "i"
			colorized_tag= tag.italic
		when "u"
			colorized_tag= tag.underline
		else
			
		end
		tags << colorized_tag
	end
return tags
end

10.times{
	puts "Enter a sentence:\n"
	sentence = gets
	puts tag sentence
	puts analyze sentence
	puts
}