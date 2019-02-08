require 'dismaltony/parsing_strategies/parsey_parse_strategy'

module DismalTony::Directives
  class GreetingDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :hello
    set_group :conversation

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q.contains?(/hello/i, /\bhi\b/i, /greetings/i) }
      qry << should { |q| !q['rel', 'discourse'].empty? }
      qry << should { |q| !q['xpos', 'UH'].empty? }
    end

    def run
      if /how are you/i.match?(query)
        DismalTony::HandledResponse.finish("~e:thumbsup I'm doing well!")
      else
        moj = random_emoji('wave', 'smile', 'rocket', 'star', 'snake', 'cat', 'octo', 'spaceinvader')
        resp = %(#{synonym_for('hello').capitalize}#{', ' + query.user['nickname'] if (0..100).to_a.sample < 75}#{['!', '.'].sample})
        DismalTony::HandledResponse.finish("~e:#{moj} #{resp}")
      end
    end
  end

  class InteractiveSignupDirective < DismalTony::Directive
    set_name :interactivesignup
    set_group :conversation

    add_param :user_id
    add_param :send_number

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ParseyParseStrategy
    end

    add_criteria do |qry|
      qry << keyword { |q| q =~ /invit(e|ation)/i }
      qry << must { |q| q =~ /send/i || q =~ /join/i }
      qry << should { |q| !q['pos', 'NUM'].empty? }
    end

    def welcome_msg
      moj = %w[exclamationmark present scroll speechbubble wave envelopearrow].sample
      "~e:#{moj} Hello! I'm #{vi.name}, a Virtual Intelligence. What is your name?"
    end

    def finish_msg
      moj = %w[wave smile envelopeheart checkbox thumbsup star toast].sample
      "~e:#{moj} Greetings, #{parameters[:user_id][:nickname]}!"
    end

    def return_cs
      cs = DismalTony::ConversationState.new(
        next_directive: self,
        next_method: :get_name,
        parse_next: false
      )
    end

    def get_last_name
      the_user = vi.data_store.select { |u| u == parameters[:user_id] }
      parameters[:user_id][:last_name] = query.raw_text
      the_user.modify_user_data(parameters[:user_id].user_data)
      DismalTony::HandledResponse.finish(finish_msg)
    end

    def get_name
      if /\s/.match?(query.raw_text)
        the_user = vi.data_store.select { |u| u == parameters[:user_id] }
        parameters[:user_id][:first_name] = query.raw_text.split(' ')[0]
        parameters[:user_id][:last_name] = query.raw_text.split(' ')[1]

        parameters[:user_id][:nickname] = parameters[:user_id][:first_name]
        the_user.modify_user_data(parameters[:user_id].user_data)
        DismalTony::HandledResponse.finish(finish_msg)
      else
        parameters[:user_id][:first_name] = query.raw_text
        parameters[:user_id][:nickname] = parameters[:user_id][:first_name]
        the_user.modify_user_data(parameters[:user_id].user_data)
        DismalTony::HandledResponse.then_do(directive: self, method: :get_last_name, data: parameters, parse_next: false, message: 'Okay! And what is your last name?')
      end
    end

    def run
      parameters[:send_number] = '+1' << query['pos', 'NUM'].first.to_s
      ncs = query.previous_state.clone
      ncs.merge(return_cs)
      parameters[:user_id] = DismalTony::UserIdentity.new(
        user_data: { phone: parameters[:send_number] },
        conversation_state: ncs
      )
      vi.data_store.new_user(user_data: parameters[:user_id].user_data)
      vi.say_through(DismalTony::SMSInterface.new(parameters[:send_number]), welcome_msg)
      DismalTony::HandledResponse.finish("~e:thumbsup Okay! I sent the message to #{parameters[:send_number]}")
    end
  end
end
