class SayHello < DismalTony::QueryHandler

  def handler_start
    @handler_name = 'say-hello'
    @patterns = ['^(?:say )?hello ?(?:,?(?:to (?<destination>\\d{10}|.+)))?(?:,?\\s?#{@vi.name}[!.]?)?'].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    @data = { 'destination' => '' }
  end

  def message
    "Hello! I'm #{@vi.name}. I'm a virtual intelligence " \
    'designed for easy execution and automation of tasks.'
  end

  def direct_message()
    if /\d+/ =~ (@data['destination'])
      @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), '~e:wave ' + message)
    else
      error_out
    end
  end

  def activate_handler(query)
    parse query
    if @data['destination'].nil?
      "I'll greet you!"
    else
      "I'll send a greeting to #{@data['destination']}"
    end
  end

  def activate_handler!(query)
    parse query
    if @data['destination'].nil?
      DismalTony::HandledResponse.new('~e:wave ' + message, nil)
    else
      direct_message
      DismalTony::HandledResponse.new("Okay! I greeted #{@data['destination']}", nil)
    end
  end
end
