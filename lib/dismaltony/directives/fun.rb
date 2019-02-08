require 'dismaltony/parsing_strategies/parsey_parse_strategy'

module DismalTony::Directives
  class DrinkMixDirective < DismalTony::Directive
    set_name :drinkmix
    set_group :fun
    add_param :drink

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q.verb&.any_of?(/want/i, /like/i, /mix/i, /make/i, /pick/i, /choose/i) }
      qry << keyword { |q| q.children_of(q.verb).any? { |c| c =~ /drink/i } }
      qry << should { |q| q =~ /please/i }
    end

    def run
      parameters[:drink] = ['Glass of Water', 'Old Fashioned', 'Zombie', 'Mai Tai', 'Rum & Coke', 'Gin & Tonic', 'Pepsi Crystal'].sample
      moj = %w[martini pineapple think tropicaldrink beer cheers toast champagne].sample

      DismalTony::HandledResponse.finish("~e:#{moj} Okay, #{query.user['nickname']}. Have a #{parameters[:drink]}!")
    end
  end
end
