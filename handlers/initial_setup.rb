DismalTony.create_handler do
    @handler_name = 'initial-setup'
    @patterns = [/(begin|setup|start)/i]

  def get_name(query, user)
    @data['name'] = query
    user['nickname'] = query
    DismalTony::HandledResponse.finish("~e:thumbsup Great! You're all set up, #{user['nickname']}!")
  end

  def message
    "Hello! I'm #{@vi.name}. I'm a virtual intelligence " \
    'designed for easy execution and automation of tasks.' \
    "\n\n" \
    "Let's start simple: What should I call you?"
  end

  def activate_handler(_query, _user)
    "I'll do initial setup"
  end

  def activate_handler!(_query, _user)
    DismalTony::HandledResponse.then_do(self, 'get_name', message)
  end
end
