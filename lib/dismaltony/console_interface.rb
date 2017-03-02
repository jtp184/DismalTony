module DismalTony
  class ConsoleInterface < DialogInterface
    def send(msg)
      puts msg
    end
  end
end
