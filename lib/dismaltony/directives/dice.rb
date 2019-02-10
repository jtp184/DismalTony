require 'dismaltony/parsing_strategies/parsey_parse_strategy'
require 'gaming_dice'

module DismalTony::Directives
  class DiceRollDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    set_name :diceroll
    set_group :fun

    add_param :result

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /\broll\b/i }
      qry << must { |q| q =~ /(((a |\d+)d(\d+)(e)?(\+\d+|\-\d+)?)( \& | \+ )*)/i }
    end

    def run
      rolls = query.raw_text.scan(/(((a |\d+)d(\d+)(e)?(\+\d+|\-\d+)?)( \& | \+ )*)/i)
      frags[:result] = rolls.map! { |r| GamingDice.roll(r[0]) }
      result_string = if rolls.length == 1
                        rolls.first
                      else
                        rolls.join(', ')
      end

      resp = '~e:dice '
      resp << "Okay! The result#{rolls.length == 1 ? ' is' : 's are'}: #{result_string}."
      return_data(frags[:result])
      DismalTony::HandledResponse.finish(resp)
    end
  end
end
