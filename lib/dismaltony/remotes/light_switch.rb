class LightSwitch < DismalTony::RemoteControl
  def initialize
    @subject = 'light'
    @predicates = ['turn_on', 'turn_off', 'check_light']
    @switch = false
  end

  def turn_on
    @switch = true
    `say Light On`
    DismalTony::HandledResponse.finish "~e:lightbulb Okay! I turned them on."
  end

  def turn_off
    @switch = false
    `say Light Off`
    DismalTony::HandledResponse.finish "~e:lightbulb Okay! I turned them off."
  end

  def check_light
    if @switch
      DismalTony::HandledResponse.finish "~e:lightbulb The light is on!"
    else
      DismalTony::HandledResponse.finish "~e:moon The light is off."
    end
  end
end