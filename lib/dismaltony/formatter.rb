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

      result = Formatter.colorize(result, opts[:color]) if opts[:color]
      em = opts[:use_icon] if opts[:use_icon]
      result = Formatter.add_icon(result, em) unless opts[:icon] == false

      result
    end

    # Takes +str+ and an emoji +emo+ and creates a standard formatted string
    def self.add_icon(str, emo)
      "[#{DismalTony::EmojiDictionary[emo]}]: #{str}"
    end

    # Method for colorizing text in the command output
    #
    # * +input+ - the message to colorize
    # * +color+ - a Symbol corresponding to the color to use.
    # Valid values are: <tt>:black, :red, :green, :yellow, :blue, :magenta, :cyan, :gray,</tt>
    # <tt>:bg_black, :bg_red, :bg_green, :bg_yellow, :bg_blue, :bg_magenta, :bg_cyan, :bg_gray,</tt>
    # :bold, :italic, :underline, :blink, :reverse_color</tt>
    # * +parse+ - whether or not to extract the message from the icon using Printer::OUTGOING
    def self.colorize(input, color, parse = false)
      if parse
        md = Formatter::OUTGOING.match(input)
        txt = md['message']
      else
        txt = input
      end

      msg_color = case color.to_sym
                  when :black
                    "\e[30m#{txt}\e[0m"
                  when :red
                    "\e[31m#{txt}\e[0m"
                  when :green
                    "\e[32m#{txt}\e[0m"
                  when :yellow
                    "\e[33m#{txt}\e[0m"
                  when :blue
                    "\e[34m#{txt}\e[0m"
                  when :magenta
                    "\e[35m#{txt}\e[0m"
                  when :cyan
                    "\e[36m#{txt}\e[0m"
                  when :gray
                    "\e[37m#{txt}\e[0m"
                  when :bg_black
                    "\e[40m#{txt}\e[0m"
                  when :bg_red
                    "\e[41m#{txt}\e[0m"
                  when :bg_green
                    "\e[42m#{txt}\e[0m"
                  when :bg_yellow
                    "\e[43m#{txt}\e[0m"
                  when :bg_blue
                    "\e[44m#{txt}\e[0m"
                  when :bg_magenta
                    "\e[45m#{txt}\e[0m"
                  when :bg_cyan
                    "\e[46m#{txt}\e[0m"
                  when :bg_gray
                    "\e[47m#{txt}\e[0m"
                  when :bold
                    "\e[1m#{txt}\e[22m"
                  when :italic
                    "\e[3m#{txt}\e[23m"
                  when :underline
                    "\e[4m#{txt}\e[24m"
                  when :blink
                    "\e[5m#{txt}\e[25m"
                  when :reverse_color
                    "\e[7m#{txt}\e[27m"
                  else
                    txt
      end

      return "#{md['moji']}#{msg_color}" if parse
      msg_color
    end

    # Instance method for accessing Colorizing. Passes on values for +input+, +color+, and +parse+
    def colorize(input, color, parse = false)
      Formatter.colorize(input, color, parse)
    end
  end
end
