module DismalTony
  class ConsoleInterface < DialogInterface
    attr_accessor :color_on
    def send(msg)
      incoming = /(?:\[(?<moji>.+)\]\: )(?<message>[^\n]+)/
      md = incoming.match msg
      puts "\e[36m[ #{md['moji']}  ]: #{md['message']} \e[0m" 
    end

    def recieve
      gets
    end
  end
end
