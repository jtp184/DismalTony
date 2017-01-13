class SendText < Tony::QueryHandler
  def initialize
    @handler_name = 'send-text'
    @patterns = ['^(?:(?:send a? ?(?:message|text))|(?:message|text))\\s?(?:to)?\\s?(?<destination>\d{10}|(?:\\w| )+) (?:saying|that says) (?<message>.+)'].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    @data = { 'destination' => '', 'message' => '' }
  end

  def lookup_name(str)
    # TODO: integrate with address book
  end

  def format_number(str)
    '+1' + str
  end

  def activate_handler!(query, vi)
    parse query

    if /\d+/ =~ (@data['destination'])
      vi.say_through(Tony::SMSInterface.new(@data['destination']), @data['message'])
    else
      error_out
    end

    Tony::HandledResponse.new('Okay! I sent your message.', nil)
  end

  def explain; end

  def activate_handler(query, _vi)
    parse query
    "I will message #{@data['destination']} and say \'#{@data['message']}\'"
  end
end
