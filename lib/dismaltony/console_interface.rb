module DismalTony
  class ConsoleInterface < DialogInterface
    def initialize(virtual)
      @vi = virtual
    end

    def send(msg)
      puts msg
    end
  end
end
