module Tony
  class ConsoleInterface < DialogInterface
    attr_accessor :color_on
    def send(msg)
      puts msg
    end

    def recieve
      gets
    end
  end
end
