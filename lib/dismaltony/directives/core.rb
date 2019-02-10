require 'dismaltony/parsing_strategies/parsey_parse_strategy'
require 'duration'

module DismalTony::Directives
  class GreetingDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :hello
    set_group :core

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q.contains?(/hello/, /\bhi\b/, /greetings/) }
      qry << should { |q| !q['rel', 'discourse'].empty? }
      qry << could { |q| !q['xpos', 'UH'].empty? }
    end

    def run
      if /how are you/.match?(query)
        DismalTony::HandledResponse.finish("~e:thumbsup I'm doing well!")
      else
        moj =
          random_emoji(
            'wave',
            'smile',
            'rocket',
            'star',
            'snake',
            'cat',
            'octo',
            'spaceinvader'
          )
        resp =
          "#{synonym_for('hello').capitalize}#{if (0..100).to_a.sample < 75
            ', ' + query.user['nickname']
          end}#{['!', '.'].sample}"
        DismalTony::HandledResponse.finish("~e:#{moj} #{resp}")
      end
    end
  end

  class SelfDiagnosticDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :selfdiagnostic
    set_group :debug

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /diagnostic/i }
      qry << must { |q| q.contains?(/run/i, /execute/i, /perform/i) }
    end

    def run
      good_moj = random_emoji('tophat', 'thumbsup', 'star', 'checkbox', 'chartup') if ParseyParse.run_parser('Diagnostic successful')
      return_string = "Diagnostic Successful!\n\n"
      return_string << "    Time: #{Time.now.strftime('%F %l:%M%P')}\n"
      return_string << "    VI: #{vi.name}\n"
      return_string << "    Version: #{DismalTony::VERSION}\n"
      return_string << "    User: #{vi.user['nickname']}\n"
      return_string << "    Directives: #{vi.directives.length}\n"
      DismalTony::HandledResponse.finish("~e:#{good_moj} #{return_string}")
    rescue StandardError
      bad_moj = random_emoji('cancel', 'caution', 'alarmbell', 'thumbsdown', 'thermometer', 'worried')
      DismalTony::HandledResponse.finish("~e:#{bad_moj} Something went wrong!")
    end
  end
end
