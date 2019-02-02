module DismalTony # :nodoc:
  # Responsible for taking strings and formatting them according to project guidelines
  class Formatter
    # Options for the format
    attr_reader :opts

    # a Regexp which matches a message sent with the standard DismalTony format
    OUTGOING = /(?<label>\[(?<moji>.+)\]\: )(?<message>.+)/.freeze
    # a Regexp which matches a message string, and includes support for extracting the emoji signifier
    INCOMING = /(?:~e:(?<emote>\w+\b) )?(?<message>(.|\s)+)/.freeze

    # Sets this Formatter's +opts+ hash to +args+
    def initialize(**args) # :nodoc:
      @opts = args
    end

    # The main function of the class. Parses +opts+ to determine what transformations to apply to +str+ before returning it
    def self.format(str, opts = {})
      md = Formatter::INCOMING.match(str)
      em = (md['emote'] || 'smile')

      result = md['message']

      em = get_icon(em)
      em = opts[:use_icon] if opts[:use_icon]

      result = Formatter.add_icon(result, em) unless opts[:icon] == false
      result = extra_space(result) if opts[:extra_space]
      result
    end

    # Gets an emoji from its internal name.
    def self.get_icon(emo)
      DismalTony::EmojiDictionary[emo]
    end

    # Takes +str+ and an emoji +emo+ and creates a standard formatted string
    def self.add_icon(str, emo)
      "[#{emo}]: #{str}"
    end

    # Uses String#gsub to pad +str+ with extra space before a closing
    # square bracket, allowing the default text output to work in terminal.
    def self.extra_space(str)
      str.gsub(/]:/, '  ]:')
    end
  end
end
