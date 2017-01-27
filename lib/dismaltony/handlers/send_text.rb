class SendText < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'send-text'
    @patterns = ['^(?:(?:send a? ?(?:message|text))|(?:message|text))\\s?(?:to)?\\s?(?<destination>\d{10}|(?:\\w| )+) (?:saying|that says) (?<message>.+)']
    @data = { 'destination' => '', 'message' => '' }
  end

  def lookup_name(str)
    # TODO: integrate with address book
  end

  def format_number(str)
    '+1' + str
  end

  def activate_handler!(query, user)
    parse query

    if /\d+/ =~ (@data['destination'])
      @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), @data['message'])
    else
      error_out
    end

    DismalTony::HandledResponse.new('Okay! I sent your message.', nil)
  end

  def explain; end

  def activate_handler(query, user)
    parse query
    "I will message #{@data['destination']} and say \'#{@data['message']}\'"
  end
end
