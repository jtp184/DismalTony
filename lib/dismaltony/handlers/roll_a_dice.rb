class RollADice < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'roll-dice'
    @patterns = [/roll (?:a|(?<count>\d+) )(?:(?<sides>\d+) sided)?(?: dice)?(?:D(?<sides>\d))?/]
    @subhandlers = {'get_sides' => /\d+/}
  end

  def activate_handler(query, user)
  	md = parse query
  	if md['sides'].nil?
  		"I'll figure out how many sides you want, then roll a dice!"
  	else
  		"I'll roll a #{@data['sides']} sided dice!"
  	end
  	
  end

  def get_sides(query)
    if query =~ @subhandlers['sides']
      @data['sides'] = query
      result = (0..sides).to_a.sample
      DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
    end
  end

  def activate_handler!(query, user)
  	md = parse query
  	if md['sides'].nil?
  		DismalTony::HandledResponse.then_do(self, 'get_sides', '~e:think Okay! Just tell me how many sides you want on it.')
  	else
      result = 0
      case @data['count']
      when nil
        result = (0..@data['sides']).to_a.sample
        DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
      else
        @data['count'].times {
          result += (0..@data['sides']).to_a.sample
        }
        DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
      end
    end
  end
end
