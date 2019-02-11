require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives
  class SendTextMessageDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    set_name :send_text
    set_group :conversation

    expect_frags :sendto, :sendmsg

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /text/i }
      qry << could { |q| q =~ /send/i }
      qry << could { |q| q =~ /message/i }
    end

    def get_tel
      frags[:sendto] = query.raw_text
      DismalTony::HandledResponse.then_do(directive: self, method: :get_msg, message: '~e:speechbubble Okay, what shall I say to them?', parse_next: false, data: frags)
    end

    def get_msg
      frags[:sendmsg] = query.raw_text
      vi.say_through(DismalTony::SMSInterface.new(frags[:sendto]), frags[:sendmsg])
      DismalTony::HandledResponse.finish('~e:speechbubble Okay! I sent the message.')
    end

    def run
      resp = nil
      frags[:sendto] = query['pos', 'NUM'].first&.to_s
      if frags[:sendto].nil?
        frags[:sendto] = if /^me$/i.match?(query.children_of(query.verb)&.first)
                                query.user[:phone]
                              elsif /[a-z]*/i.match?(query.children_of(query.verb)&.first)
                                # Code for if it's a name
                                nil
                              end
      else
        resp = DismalTony::HandledResponse.finish("~e:frown That isn't a valid phone number!") if (frags[:sendto] =~ /^\d{10}$/).nil?
                          end

      return resp if resp

      if frags[:sendto].nil?
        resp = DismalTony::HandledResponse.then_do(directive: self, method: :get_tel, message: '~e:pound Okay, to what number should I send the message?', parse_next: false, data: frags) if frags[:sendto].nil?
      else
        frags[:sendmsg] = query.raw_text.split(query['pos', 'VERB'].select { |w| w.any_of?(/says/i, /say/i) }.first.to_s << ' ')[1]
        vi.say_through(DismalTony::SMSInterface.new(frags[:sendto]), frags[:sendmsg])
        resp = DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent the message.')
      end
      resp
                        end
  end

  class InteractiveSignupDirective < DismalTony::Directive
    set_name :interactivesignup
    set_group :conversation

    expect_frags :user_id, :send_number

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /invit(e|ation)/ }
      qry << must { |q| q =~ /send/ || q =~ /join/ }
      qry << should { |q| q.numerals? }
    end

    def welcome_msg
      moj = %w[exclamationmark present scroll speechbubble wave envelopearrow]
        .sample
      "~e:#{moj} Hello! I'm #{vi
        .name}, a Virtual Intelligence. What is your name?"
    end

    def finish_msg
      moj = %w[wave smile envelopeheart checkbox thumbsup star toast].sample
      "~e:#{moj} Greetings, #{frags[:user_id][:nickname]}!"
    end

    def return_cs
      cs =
        DismalTony::ConversationState.new(
          next_directive: self, next_method: :get_name, parse_next: false
        )
    end

    def get_last_name
      the_user = vi.data_store.select { |u| u == frags[:user_id] }
      frags[:user_id][:last_name] = query.raw_text
      the_user.modify_user_data(frags[:user_id].user_data)
      DismalTony::HandledResponse.finish(finish_msg)
    end

    def get_name
      if /\s/.match?(query.raw_text)
        the_user = vi.data_store.select { |u| u == frags[:user_id] }
        frags[:user_id][:first_name] = query.raw_text.split(' ')[0]
        frags[:user_id][:last_name] = query.raw_text.split(' ')[1]

        frags[:user_id][:nickname] = frags[:user_id][:first_name]
        the_user.modify_user_data(frags[:user_id].user_data)
        DismalTony::HandledResponse.finish(finish_msg)
      else
        frags[:user_id][:first_name] = query.raw_text
        frags[:user_id][:nickname] = frags[:user_id][:first_name]
        the_user.modify_user_data(frags[:user_id].user_data)
        DismalTony::HandledResponse.then_do(
          directive: self,
          method: :get_last_name,
          data: frags,
          parse_next: false,
          message: 'Okay! And what is your last name?'
        )
      end
    end

    def run
      frags[:send_number] = '+1' << query['pos', 'NUM'].first.to_s
      ncs = query.previous_state.clone
      ncs.merge(return_cs)
      frags[:user_id] =
        DismalTony::UserIdentity.new(
          user_data: { phone: frags[:send_number] },
          conversation_state: ncs
        )
      vi.data_store.new_user(user_data: frags[:user_id].user_data)
      vi.say_through(
        DismalTony::SMSInterface.new(frags[:send_number]), welcome_msg
      )
      DismalTony::HandledResponse.finish(
        "~e:thumbsup Okay! I sent the message to #{frags[:send_number]}"
      )
    end
  end
end
