module DismalTony
  class ConsoleInterface < DialogInterface
    attr_accessor :color_on
    def send(msg, style = :none)
      incoming = /(?:\[(?<moji>.+)\]\: )(?<message>[^\n]+)/
      md = incoming.match msg
      case style
      when :none
        puts "[#{md['moji']}]: #{md['message']}" 
      when :space
        puts "[  #{md['moji']}  ]: #{md['message']}" 
      when :color
        puts "\e[36m[ #{md['moji']}  ]: #{md['message']}\e[0m"
      end
    end

    def recieve
      gets
    end
  end
end
