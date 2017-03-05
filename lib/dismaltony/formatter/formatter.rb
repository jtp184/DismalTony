require 'duration'

module DismalTony
  module Formatter
    class Printer 
      OUTGOING = /(?<label>\[(?<moji>.+)\]\: )(?<message>[^\n]+)/
      INCOMING = /(?:~e:(?<emote>\w+\b) )?(?<message>.+)/

      def initialize(**args)
        @opts = args
      end

      def self.format(str, opts)
        md = Printer::INCOMING.match(str)
        em = (md['emote'] || 'smile')

        result = md['message']

        result = Printer.colorize(result, opts[:color]) if opts[:color]
        result = Printer.add_icon(result, em) unless opts[:icon] == false

        return result
      end

      def self.add_icon(str, emo)
        "[#{DismalTony::EmojiDictionary[emo]}]: #{str}"
      end

      def self.colorize(input, color, parse = false)
        if parse
          md = ConsoleInterface::MSG_RGX.match(input)
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

        return "#{md['avatar']}#{msg_color}" if parse
        return msg_color
      end

      def colorize(input, color, parse = false)
        Printer.colorize(input, color, parse)
      end
    end

    class ProgressBar
      attr_accessor :current, :total, :opts

      def initialize(total, opts = {:color => 'gray', :width => 80}, &block)
        @current = (opts[:start] || 0)
        @total = total.to_i
        @opts = opts
        @multi = Mutex.new
        @once_done = block_given? ? block : Proc.new { }
      end

      def increment(step = 1)
        @multi.synchronize do
          return if complete?
          @current += step.to_i
        end
      end

      def redisplay

      end

      def display
        # Gives us an instanced printer with a shorter name
        pr = Formatter::Printer.new(:icon => false)

        # Quick references
        started = @opts[:started_at]
        width = @opts[:width]
        pad = @total.to_s.size * 2 + 3
        pct = @current.to_f / @total.to_f
        section = '+' * (pct * width).ceil
        remain = ' ' * (width - section.length)
        
        # where we're sticking all of these various symbols
        result = []

        # If we've given this a label, append it
        result << options[:label] if @opts[:label]

        # splits based on color
        if @opts[:color]
          result << pr.format((" " * pad) << "#{@current}/#{@total}", {:color => @opts[:color]})
          result << pr.format("|", {:color => :bg_white})
          result << pr.format(pr.format(section, {:color => @opts[:color]}), {:color => "bg_" << @opts[:color]})
          result << pr.format("|", {:color => :bg_white})
        else
          result << pr.format((" " * pad) << "#{@current}/#{@total}")
          result << pr.format("|", {:color => :bg_white})
          result << pr.format(pr.format(section, {:color => 'white'}), {:color => "bg_white"})
          result << pr.format("|", {:color => :bg_white})
        end

        # Append the counter
        if started
          time_diff = Duration.new((Time.now - @opts[:started_at]).to_i)
          if time_diff.minutes > 0
            if time_diff.hours > 0
              result << time_diff.format("%H:%M:%S")
            else
              result << time_diff.format("%M:%S")
            end         
          else
            result << time_diff.format("00:%S")         
          end
        end

        result << ''
        result.join('  ')
      end
    end
  end
end