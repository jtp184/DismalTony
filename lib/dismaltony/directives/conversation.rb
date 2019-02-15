require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives
  class SendTextMessageDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    set_name :send_text
    set_group :conversation

    expect_frags :send_to, :message

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.key_phrases.map(&:text).any? { |t| t =~ /text/i || t =~ /message/i } }
      qry << must { |q| q.other_entity? }
      qry << must { |q| q.other_entity&.text&.match?(/\d{10}/) }
      qry << should { |q| q.contains?(/\bsays? /i) }
    end

    def run
      frags[:send_to] = query.other_entity.text
      frags[:message] = query.raw_text.split(/\bsays? /i)[1]
      vi.say_through(DismalTony::SMSInterface.new(frags[:send_to]), frags[:message])
      return_data(frags)
      DismalTony::HandledResponse.finish('~e:thumbsup Okay! I sent the message.')
    end
  end

  class InteractiveSignupDirective < DismalTony::Directive
    set_name :interactive_signup
    set_group :conversation

    expect_frags :phone, :first_name, :last_name, :nickname, :uuid

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /invit(e|ation)/ }
      qry << must { |q| q =~ /send/ || q =~ /join/ }
      qry << must { |q| q.other_entity&.text&.match?(/\d{10}/) }
      qry << must { |q| q.other_entity? }
    end

    def run
      frags[:phone] = q.other_entity.text
      
      noob = vi.data_store.new_user(blank_user)
      frags[:uuid] = noob[:uuid]

      vi.say_through(DismalTony::SMSInterface.new(frags[:send_number]), welcome_msg)
      
      moj = positive_emoji
      DismalTony::HandledResponse.finish(
        "~e:#{moj} Okay! I sent the message to #{frags[:send_number]}"
      )
    end

    def get_last_name
      frags[:last_name] = query.raw_text
      DismalTony::HandledResponse.then_do(
        message: "~e:pencil Okay! And what is your complete last name?",
        next_directive: self,
        method: :get_nickname,
        data: frags
      )
    end

    def get_first_name
      frags[:first_name] = query.raw_text
      DismalTony::HandledResponse.then_do(
        message: "~e:thumbsup Okay! And what is your complete last name?",
        next_directive: self,
        method: :get_first_name,
        data: frags
      )
    end

    def get_nickname
      frags[:nickname] = query.raw_text

      vi.data_store.update_user(frags[:uuid]) do |usr|
        usr[:first_name] = frags[:first_name]
        usr[:last_name] = frags[:last_name]
        usr[:nickname] = frags[:nickname]
      end

      DismalTony::HandledResponse.finish(finish_msg)
    end
    
    private

    def blank_user
      DismalTony::UserIdentity.new(
        user_data: { phone: frags[:phone] },
        conversation_state: begin_cs
      )
    end

    def welcome_msg
      moj = random_emoji('exclamationmark', 'present', 'scroll', 'speechbubble', 'wave', 'envelopearrow')
      "~e:#{moj} Hello! I'm #{vi.name}"
      ", a Virtual Intelligence. I'm going to take you through "
      "interactively signing up to use my services. Let's begin with your full first name."
    end

    def finish_msg
      moj = random_emoji('wave', 'smile', 'envelopeheart', 'checkbox', 'thumbsup', 'star', 'toast')
      "~e:#{moj} Congratulations, #{frags[:user_id][:nickname]}. You're all ready!"
    end

    def begin_cs
      cs =
        DismalTony::ConversationState.new(
          next_directive: self,
          next_method: :get_first_name,
          data: frags,
          parse_next: false
        )
    end
  end
end
