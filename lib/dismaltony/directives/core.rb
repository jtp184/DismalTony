require 'dismaltony/parsing_strategies/parsey_parse_strategy'
require 'duration'

module DismalTony::Directives
  class SendTextMessageDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    set_name :send_text
    set_group :core

    add_param :sendto
    add_param :sendmsg

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << keyword { |q| q =~ /text/i }
      qry << should { |q| q.root =~ /text/i }
      qry << should { |q| q.children_of(q.verb).any? { |w| w.pos == 'NUM' } }
      qry << could { |q| q =~ /send/i }
      qry << could { |q| q =~ /message/i }
    end

    def get_tel
      parameters[:sendto] = query.raw_text
      DismalTony::HandledResponse.then_do(directive: self, method: :get_msg, message: '~e:speechbubble Okay, what shall I say to them?', parse_next: false, data: parameters)
    end

    def get_msg
      parameters[:sendmsg] = query.raw_text
      vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
      DismalTony::HandledResponse.finish('~e:speechbubble Okay! I sent the message.')
    end

    def run
      resp = nil
      parameters[:sendto] = query['pos', 'NUM'].first&.to_s
      if parameters[:sendto].nil?
        parameters[:sendto] = if /^me$/i.match?(query.children_of(query.verb)&.first)
                                query.user[:phone]
                              elsif /[a-z]*/i.match?(query.children_of(query.verb)&.first)
                                # Code for if it's a name
                                nil
                              end
      else
        resp = DismalTony::HandledResponse.finish("~e:frown That isn't a valid phone number!") if (parameters[:sendto] =~ /^\d{10}$/).nil?
                          end

      return resp if resp

      if parameters[:sendto].nil?
        resp = DismalTony::HandledResponse.then_do(directive: self, method: :get_tel, message: '~e:pound Okay, to what number should I send the message?', parse_next: false, data: parameters) if parameters[:sendto].nil?
      else
        parameters[:sendmsg] = query.raw_text.split(query['pos', 'VERB'].select { |w| w.any_of?(/says/i, /say/i) }.first.to_s << ' ')[1]
        vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
        resp = DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent the message.')
      end
      resp
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
      qry << keyword { |q| q =~ /diagnostic/i }
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
