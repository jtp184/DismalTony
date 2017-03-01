class InitialSetup < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'initial-setup'
    @patterns = [/(begin|setup|start)/]
  end

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

  def activate_handler(query, user)
    "I'll do initial setup"
  end
  
  def activate_handler!(query, user)
    DismalTony::HandledResponse.then_do(self, 'get_name', message)
  end

end