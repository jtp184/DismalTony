DismalTony.create_handler do
  def handler_start
    @handler_name = 'say-hello'
    @patterns = ['hello']
  end

  def get_name(query, user)
    @data['name'] = query
    user['first_name'] = query
    @vi.say("~e:thumbsup Awesome! Okay, here's what you can do")
    @vi.say('~e:ticket You can say something like "Give Beth 10 points" and it will give them to her')
    DismalTony::HandledResponse.finish("~e:think You can say something like \"How many points does Beth have?\" and I'll tell you!")
  end

  def message
    "Hello, I'm #{@vi.name}. In this demo, I keep track of points in a simple multi-user game. " \
    "Let's start simple: What's your first name?"
  end

  def activate_handler(_query, _user)
    "I'll greet you!"
  end

  def activate_handler!(_query, _user)
    DismalTony::HandledResponse.then_do(self, 'get_name', message)
  end
end
