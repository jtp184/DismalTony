class SayHello < DismalTony::QueryHandler

  def handler_start
    @handler_name = 'say-hello'
    @patterns = ['^(?:say )?hello ?(?:,?(?:to (?<destination>\\d{10}|.+)))?(?:,?\\s?#{@vi.name}[!.]?)?']
    @data = { 'destination' => '' }
  end

  def message(user)
    "Hello, #{user['nickname']}! I'm #{@vi.name}. I'm a virtual intelligence " \
    'designed for easy execution and automation of tasks.'
  end

  def direct_message(user)
    if /\d+/ =~ (@data['destination'])
      @vi.say_through(DismalTony::SMSInterface.new(@data['destination']), '~e:wave ' + message(user))
    else
      error_out
    end
  end

  def activate_handler(query, user)
    parse query
    if @data['destination'].nil?
      "I'll greet you!"
    else
      "I'll send a greeting to #{@data['destination']}"
    end
  end

  def activate_handler!(query, user)
    parse query
    if @data['destination'].nil?
      DismalTony::HandledResponse.finish('~e:wave ' + message(user))
    else
      direct_message(user)
      DismalTony::HandledResponse.finish("Okay! I greeted #{@data['destination']}")
    end
  end
end
