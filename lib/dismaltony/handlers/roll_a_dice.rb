DismalTony.create_handler do
  def handler_start
    @handler_name = 'roll-dice'
    @patterns = [/(?<noargs>roll a dice)/i, /roll (?<equation>.+)/i]
  end

  def activate_handler(query, user)
    if @data['noargs']
      "I'll ask how many sides you'd like, then roll it!"
    else
      "I'd roll those dice!"
    end
  end

  def activate_handler!(query, user)
    parse query
    if @data['noargs']
      DismalTony::HandledResponse.then_do(self, 'get_sides', '~e:think Okay! Just tell me how many sides you want on it.')
    else
      result = parse_rolls(@data['equation']).map { |e| e.to_s }
      DismalTony::HandledResponse.finish "~e:dice Okay! The results are: #{result.join(' ')}"
    end
  end

  def get_sides(query, user)
    if query =~ /\d+/
      result = roll(1, query.to_i, 0, false)
      DismalTony::HandledResponse.finish "~e:dice Okay! The result is: #{result}!"
    else
      DismalTony::HandledResponse.finish "~e:frown I'm sorry, I didn't understand that!"
    end
  end

  def query_result(query, _user)
    parse_rolls(query)
  end

  def parse_rolls(str)
    results = []
    individuals = str.split(", ").each do |terms|
      operators = []
      dices = []
      terms.scan(/(((a |\d+)d(\d+)(e)?(\+\d+|\-\d+)?)( \& | \+ )*)/i) do |match|
        # 2 = count
        # 3 = sides
        # 4 = explode
        # 5 = flat bonus
        # 6 = continuant
        count = match[2]
        if count.include? 'a'
          count = 1 
        else
          count = count.to_i
        end
        face = (match[3].to_i || 0)
        explode = !match[4].nil?
        flat = (match[5].to_i || 0)
        op = (match[6] || '&')  
        
        operators << op
        dices << roll(count, face, flat, explode)
      end
      results << dices if operators.any? { |op| op == '&' }
      results << dices.inject(:+) if operators.any? { |op| op == '+' }
    end
    return results
  end

  def roll(count, faces, bonus, explodes)
    result = 0
    count.times {
      this_roll = (1..faces).to_a.sample 

      if explodes
        this_roll += roll(count, faces, bonus, explodes) if this_roll == faces
      end

      result += this_roll
    }
    result += bonus
  end
end