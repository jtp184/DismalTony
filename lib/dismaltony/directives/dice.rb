require 'gaming_dice'

module DismalTony::Directives 
  class DiceRollDirective < DismalTony::Directive
    set_name :diceroll
    set_group :fun

    add_param :result

    add_criteria do |qry|
      qry << keyword { |q| q =~ /\broll\b/i }
      qry << must { |q| q =~ /(((a |\d+)d(\d+)(e)?(\+\d+|\-\d+)?)( \& | \+ )*)/i }
    end

    def run
      rolls = query.raw_text.scan(/(((a |\d+)d(\d+)(e)?(\+\d+|\-\d+)?)( \& | \+ )*)/i)
      parameters[:result] = rolls.map! { |r| GamingDice.roll(r[0]) }
      result_string = if rolls.length == 1
        rolls.first
      else
        rolls.join(", ")
      end

      resp = "~e:dice "
      resp << "Okay! The result#{rolls.length == 1 ? ' is': 's are'}: #{result_string}."

      DismalTony::HandledResponse.finish(resp)
    end
  end
end