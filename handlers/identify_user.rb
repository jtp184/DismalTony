DismalTony.create_handler do
  @handler_name = 'identify-user'
  @patterns = [/(?<whoami>who am i\??)|(?<name>what(?: [i\'])?s my name\??)/i]

  def activate_handler!(query, user)
    md = parse query
    if md['whoami']
      DismalTony::HandledResponse.finish("~e:smile You are #{user.user_data['nickname']}!")
    elsif md['name']
      DismalTony::HandledResponse.finish("~e:smile Your name is #{user.user_data['nickname']}!")
    end
  end

  def activate_handler(query, _user)
    parse query
    'I will tell you who you are!'
  end
end
