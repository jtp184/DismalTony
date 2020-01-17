require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives # :nodoc:
  # Suggests a drink to make
  class DrinkMixDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers

    set_name :drinkmix
    set_group :fun

    expect_frags :drink

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q =~ /drink/i } 
      qry << must { |q| q.verb&.any_of?(/want/i, /like/i, /mix/i, /make/i, /pick/i, /choose/i) }
    end

    # Chooses from
    def run
      return_data(frags[:drink])
      
      moj = %w[martini pineapple think tropicaldrink beer cheers toast champagne].sample
      DismalTony::HandledResponse.finish("~e:#{moj} Okay, #{query.user['nickname']}. Have a #{frags[:drink]}!")
    end

    private

    # Randomly selects a drink
    def pick_drink
      frags[:drink] = [
        'Glass of Water', 
        'Old Fashioned', 
        'Zombie', 
        'Mai Tai', 
        'Rum & Coke', 
        'Gin & Tonic', 
        'Pepsi Crystal'
      ].sample
    end
  end
end
