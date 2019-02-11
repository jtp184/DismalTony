require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives
  class DrinkMixDirective < DismalTony::Directive
    set_name :drinkmix
    set_group :fun

    expect_frags :drink

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /drink/i } 
      qry << must { |q| q.verb&.any_of?(/want/i, /like/i, /mix/i, /make/i, /pick/i, /choose/i) }
      qry << should { |q| q =~ /please/i }
    end

    def run
      frags[:drink] = ['Glass of Water', 'Old Fashioned', 'Zombie', 'Mai Tai', 'Rum & Coke', 'Gin & Tonic', 'Pepsi Crystal'].sample
      moj = %w[martini pineapple think tropicaldrink beer cheers toast champagne].sample

      DismalTony::HandledResponse.finish("~e:#{moj} Okay, #{query.user['nickname']}. Have a #{frags[:drink]}!")
    end
  end
end
