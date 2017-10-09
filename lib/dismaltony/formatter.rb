require 'duration'

module DismalTony # :nodoc:
  # Responsible for taking strings and formatting them according to project guidelines
  class Formatter
    # a Regexp which matches a message sent with the standard DismalTony format
    OUTGOING = /(?<label>\[(?<moji>.+)\]\: )(?<message>.+)/
    # a Regexp which matches a message string, and includes support for extracting the emoji signifier
    INCOMING = /(?:~e:(?<emote>\w+\b) )?(?<message>(.|\s)+)/

    def initialize(**args) # :nodoc:
      @opts = args
    end

    # The main function of the class. Parses +opts+ to determine what transformations to apply to +str+ before returning it
    def self.format(str, opts = {})
      md = Formatter::INCOMING.match(str)
      em = (md['emote'] || 'smile')

      result = md['message']

      em = opts[:use_icon] if opts[:use_icon]
      result = Formatter.add_icon(result, em) unless opts[:icon] == false
      result = extra_space(result) if opts[:extra_space]
      result
    end

    # Takes +str+ and an emoji +emo+ and creates a standard formatted string
    def self.add_icon(str, emo)
      "[#{DismalTony::EmojiDictionary[emo]}]: #{str}"
    end

    def self.extra_space(str)
      str.gsub(/]:/, "  ]:")
    end
  end
end
