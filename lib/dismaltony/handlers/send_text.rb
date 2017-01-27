class SendText < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'send-text'
    @patterns = ['(?<directiveless>send a text)','^(?:(?:send a? ?(?:message|text))|(?:message|text))\\s?(?:to)?\\s?(?<destination>\d{10}|(?:\\w| )+) (?:saying|that says) (?<message>.+)']
    @data = { 'destination' => '', 'message' => '' }
    @subhandlers = {'get_destination' => /\d+/}
  end

  def lookup_name(str)
    # TODO: integrate with address book
  end

  def format_number(str)
    '+1' + str
  end

  def get_message(query, user)
    @data['message'] = query
    @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), @data['message'])
    DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent your message.')
  end

  def get_destination(query, user)
    if query =~ @subhandlers['get_destination']
      @data['destination'] = query
      DismalTony::HandledResponse.then_do(self, 'get_message', '~e:speechbubble Alright! What should I say?')
    else
      DismalTony::HandledResponse.then_do(self, 'get_destination' "~e:frown Sorry! Didn't quite get that. To whom?")
    end
  end

  def activate_handler!(query, user)
    parse query
    if @data['directiveless']
      DismalTony::HandledResponse.then_do(self, 'get_destination', '~e:pound Okay! To whom should I send it?')
    elsif /\d+/ =~ (@data['destination'])
      @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), @data['message'])
      DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent your message.')
    else
      error_out
    end

  end

  def activate_handler(query, user)
    parse query
    "I will message #{@data['destination']} and say \'#{@data['message']}\'"
  end
end
