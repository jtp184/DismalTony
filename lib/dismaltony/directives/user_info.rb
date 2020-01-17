require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives # :nodoc:
  # Accesses data within a UserIdentity
  class RetrieveUserDataDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :retrieve_user_data
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q.contains?(/who/i, /what(?:'s)?/i) }
      qry << must { |q| q.contains?(/\bi\b/i, /\bmy\b/i) }
      qry << could { |q| q.contains?(/\bis\b/i, /\bare\b/i, /\bam\b/i) }
      qry << could { |q| q.contains?(/phone|number/i, /\bname\b/i, /birthday/i, /\bemail\b/i) }
    end

    # Tries to resolve what the question is, and returns that data
    def run
      if /who am i/i.match?(query)
        who_am_i
      elsif /what('| i)?s my/i.match?(query)
        whats_my
      else
        DismalTony::HandledResponse.finish("~e:frown I'm not quite sure how to answer that.")
      end
    end

    private

    # Returns first, last, and nickname
    def who_am_i
      moj = random_emoji('think', 'magnifyingglass', 'crystalball', 'smile')
      return_data(query.user)
      DismalTony::HandledResponse.finish("~e:#{moj} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}.")
    end

    # Defers to #my_name and #my_age if subject matches them
    def whats_my
      moj = detect_emoji

      return my_name if subject == 'name'
      return my_age if subject == 'age'

      attempt = subject.tr(' ', '_').to_sym
      attempt = :phone if (attempt == :number || attempt == :phone_number)

      if query.user[attempt]
        return_data(query.user[attempt])
        DismalTony::HandledResponse.finish("~e:#{moj} Your #{subject} is #{query.user[attempt]}")
      else
        return_data(nil)
        DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know your #{subject}")
      end
    end

    # Returns the user's name
    def my_name
      return_data("#{query.user[:first_name]} #{query.user[:last_name]}")
      DismalTony::HandledResponse.finish(name_string)
    end

    # Returns the user's age
    def my_age
      age_in_years = Duration.new(Time.now - query.user[:birthday]).weeks / 52
      return_data(age_in_years) 

      age_str = "~e:#{detect_emoji} You are #{age_in_years} years old, #{query.user[:nickname]}!"
      DismalTony::HandledResponse.finish(age_str)
    end

    # Dynamically sets emoji for use
    def detect_emoji
      moj = case subject
      when /phone/i, /number/i
        'phone'
      when /name/i
        'speechbubble'
      when /birthday/i
        'calendar'
      when /age/i
        'clockface'
      when /email/i
        'envelope'
      else
        random_emoji('magnifyingglass', 'key')
      end
    end

    # The string for the name response
    def name_string
      "~e:#{detect_emoji} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}."
    end

    # Finds the subject via key phrase and converts it
    def subject
      query.key_phrase
           &.to_s
           &.downcase
    end
  end

  # Accesses data about another known user
  class RetrieveOtherUserDataDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :retrieve_other_user_data
    set_group :info

    expect_frags :other_user, :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << must { |q| q.contains?(/\bwhat(?:\b|[' i]?s)/i) }
      qry << must { |q| q.person? }
      qry << could { |q| q.contains?(/phone|number/i, /\bname\b/i, /birthday/i, /\bemail\b/i, /phone number/i) }
      qry << doesnt { |q| q =~ /\bmy\b/ }
    end

    # The user yielded by the +text_check+
    def user_for(text_check)
      return @user_for if @user_for

      names = [
        -> (u) { u[:nickname] },
        -> (u) { u[:first_name] },
        -> (u) { u[:first_name] + u[:last_name] }
      ]

      u = vi.data_store
            .users
            .find { |u| names.any? { |txt| txt.call(u) == text_check } }

      @user_for = fragments[:other_user] = u
    end

    # Returns the info asked for
    def run
      if /who is/i.match?(query)
        who_is
      elsif /what('| i)?s/i.match?(query)
        whats
      else
        DismalTony::HandledResponse.finish("~e:frown I'm not quite sure how to answer that.")
      end
    end

    private

    # Handles asking about the user in the abstract
    def who_is
      moj = random_emoji('think', 'magnifyingglass', 'crystalball', 'smile')
      
      return_data(detect_user)
      DismalTony::HandledResponse.finish("~e:#{moj} #{target}'s number is #{detect_user[:phone]}.")
    end

    # Handles asking for user details
    def whats
      return whats_age if subject == 'age'

      ky = subject.tr(' ', '_').to_sym
      ky = :phone if (ky == :number || ky == :phone_number)

      if query.user[ky]
        return_data(detect_user[ky])
        DismalTony::HandledResponse.finish("~e:#{detect_emoji} Their #{subject} is #{detect_user[ky]}")
      else
        return_data(nil)
        DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know their #{subject}")
      end
    end

    # Calculates age from birthday and returns
    def whats_age
      age_in_years = Duration.new(Time.now - detect_user[:birthday]).weeks / 52
      return_data(age_in_years) 
      
      s = "~e:#{detect_emoji} "
      s << "They are "
      s << age_in_years
      s << " years old"
      s << (rand < 0.5) ? ", #{query.user[:nickname]}" : ""
      s << "."

      return DismalTony::HandledResponse.finish(s)
    end

    # Gets the first key phrase which is not the user
    def subject
      key_phrases.reject { |phr| phr.same_token?(detect_user) }.first
    end

    # Converts the first person entity to a UserIdentity
    def detect_user
      user_for(person.text)
    end

    # Yields different emoji depending on subject
    def detect_emoji
      case subject
      when /phone/i, /number/i
        'phone'
      when /name/i
        'speechbubble'
      when /birthday/i
        'calendar'
      when /age/i
        'clockface'
      when /email/i
        'envelope'
      else
        random_emoji('magnifyingglass', 'key')
      end
    end
  end
end
