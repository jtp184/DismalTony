class RollADice < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'roll-dice'
    @patterns = [/roll (?:a|(?<count>\d+)) ?(?:(?<sides>\d+) sided)?(?: dice)?(?:d(?<sides>\d+))?/i]
    @subhandlers = {'get_sides' => /\d+/}
  end

  def activate_handler(query, user)
  	md = parse query
    if md['count'].nil? && md['sides'].nil?
      "I'll figure out how many sides you want, then roll a dice!"
    elsif md['sides'].nil?
      "I'll figure out how many sides you want, then roll a dice!"
    elsif md['count']
      "I'll roll #{@data['count']} #{@data['sides']} sided dice!"
    else
      "I'll roll a #{@data['sides']} sided dice!"
    end

  end

  def get_sides(query, user)
    if query =~ @subhandlers['get_sides']
      @data['sides'] = query.to_i
      result = (1..@data['sides']).to_a.sample
      DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
    end
  end

  def query_result(query, user)
    md = parse query
    case @data['count']
    when nil
      result = (1..(@data['sides'].to_i)).to_a.sample
    else
      rolls = []
      @data['count'].to_i.times {
        rolls << (1..@data['sides'].to_i).to_a.sample
      }
      return rolls
    end
  end

  def activate_handler!(query, user)
  	md = parse query
  	if md['sides'].nil?
  		DismalTony::HandledResponse.then_do(self, 'get_sides', '~e:think Okay! Just tell me how many sides you want on it.')
  	else
      case @data['count']
      when nil
        result = (1..(@data['sides'].to_i)).to_a.sample
        DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
      else
        rolls = []
        @data['count'].to_i.times {
          rolls << (1..@data['sides'].to_i).to_a.sample
        }
        DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{rolls.join(', ')}!"
      end
    end
  end
end
