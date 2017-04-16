DismalTony.create_handler do
  def handler_start
    @handler_name = 'light-switch'
    @patterns = [/turn (?:the )lights (?<switch>on|off)/i, /turn (?<switch>on|off)(?: the) lights/i]
  end

  def activate_handler(_query, _user)
    "~e:lightbulb I'll turn the lights #{@data['switch']}."
  end

  def activate_handler!(query, _user)
    parse query
    case @data['switch']
    when 'on'
      @vi.use_service('light', 'turn_on')
    when 'off'
      @vi.use_service('light', 'turn_off')
    else
      DismalTony::HandledResponse.error
    end
  end
end
