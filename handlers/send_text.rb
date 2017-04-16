DismalTony.create_handler do
  def handler_start
    @handler_name = 'send-text'
    @patterns = [/^(?<directiveless>send a text)[ \.]?$/i, /((?:send a )?text (?:to )?(?<destination>\d{10}|([a-z]+))?( (?:that says|saying|and say|) (?<message>.+)))/i]
    @data = { 'destination' => '', 'message' => '' }
    @QueryServices = { 'get_destination' => /\d+/ }
  end

  def lookup_name(str)
    # TODO: integrate with address book
  end

  def format_number(str)
    '+1' + str
  end

  def get_message(query, _user)
    @data['message'] = query
    @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), @data['message'])
    DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent your message.')
  end

  def get_destination(query, _user)
    if query =~ /\d{10}/
      @data['destination'] = query
      DismalTony::HandledResponse.then_do(self, 'get_message', '~e:speechbubble Alright! What should I say?')
    elsif query =~ /[a-z ]/i
      number = lookup_name(query)
      # @data['destination'] = number
      DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know how to send a text to \"#{@data['destination']}.\"")
    else
      DismalTony::HandledResponse.then_do(self, 'get_destination', "~e:frown Sorry! Didn't quite get that. To whom?")
    end
  end

  def activate_handler!(query, _user)
    parse query
    if @data['directiveless']
      DismalTony::HandledResponse.then_do(self, 'get_destination', '~e:pound Okay! To whom should I send it?')
    elsif /\d+/ =~ (@data['destination'])
      @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), @data['message'])
      DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent your message.')
    else
      number = lookup_name(@data['destination'])
      # @vi.say_through(DismalTony::SMSInterface.new(number), @data['message'])
      DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know how to send a text to \"#{@data['destination']}.\"")
    end
  end

  def activate_handler(query, _user)
    parse query
    if data['directiveless']
      "I'll get the details, then send a text!"
    else
      "I will message #{@data['destination']} and say \'#{@data['message']}\'"
    end
  end
end
