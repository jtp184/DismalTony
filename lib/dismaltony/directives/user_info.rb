module DismalTony::Directives
  class RetrieveUserDataDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    set_name :retrieve_user_data
    set_group :info

    add_criteria do |qry|
      qry << must { |q| q.contains?(/who/i, /what(?:'s)?/i) }
      qry << must { |q| q.contains?(/\bi\b/i, /\bmy\b/i) }
      qry << could { |q| q.contains?(/\bis\b/i, /\bare\b/i, /\bam\b/i)}
      qry << could { |q| q.contains?(/phone|number/i, /\bname\b/i, /birthday/i, /\bemail\b/i) }
    end

    def run
      if query =~ /who am i/i
        moj = random_emoji('think','magnifyingglass','crystalball','smile')
        return_data(query.user)
        DismalTony::HandledResponse.finish("~e:#{moj} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}.")
      elsif query =~ /what('| i)?s my/i
        seek = query.children_of(query.root).select { |w| w.rel == 'nsubj' }&.first.to_s.downcase
        moj = case seek
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

        return_data("#{query.user[:first_name]} #{query.user[:last_name]}") and return DismalTony::HandledResponse.finish("~e:#{moj} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}.") if (seek == 'name')
        age_in_years = Duration.new(Time.now - query.user[:birthday]).weeks / 52
        return_data(age_in_years) and return DismalTony::HandledResponse.finish("~e:#{moj} You are #{age_in_years} years old, #{query.user[:nickname]}!") if (seek == 'age')

        ky = seek.gsub(" ", "_").to_sym
        ky = :phone if ky == :number

        if query.user[ky]
          return_data(query.user[ky])
          DismalTony::HandledResponse.finish("~e:#{moj} Your #{seek} is #{query.user[ky]}")
        else
          return_data(nil)
          DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know your #{seek}")
        end
      else
        DismalTony::HandledResponse.finish("~e:frown I'm not quite sure how to answer that.")
      end
    end
  end

  class RetrieveOtherUserDataDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :retrieve_other_user_data
    set_group :info

    add_criteria do |qry|
      qry << must { |q| q.contains?(/what/i) }
      qry << must { |q| !Array(q.xpos 'NNP').empty? }
      qry << could { |q| q.contains?(/phone|number/i, /\bname\b/i, /birthday/i, /\bemail\b/i) }
      qry << doesnt { |q| q.contains?(/weather/i, /stocks/i) }
    end

    def user_for(text_check)
      vi.data_store.users.find { |u| (u[:nickname] == text_check) || (u[:first_name] == text_check) || (u[:first_name] + u[:last_name] == text_check) }
    end

    def run
      target = Array(query.xpos('NNP')).join
      u = user_for(target)

      if query =~ /who is/i
        moj = random_emoji('think','magnifyingglass','crystalball','smile')
        return_data(u)
        DismalTony::HandledResponse.finish("~e:#{moj} #{target}'s number is #{u[:phone]}.")
      elsif query =~ /what('| i)?s/i
        seek = Array(query.children_of(query.root).select { |w| w.rel == 'nsubj' }).join.to_s.downcase
        moj = case seek
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

        return_data("#{u[:first_name]} #{u[:last_name]}") and return DismalTony::HandledResponse.finish("~e:#{moj} Their name is #{u[:nickname]}.") if (seek =~ /\bname\b/)
        age_in_years = Duration.new(Time.now - u[:birthday]).weeks / 52
        return_data(age_in_years) and return DismalTony::HandledResponse.finish("~e:#{moj} They are #{age_in_years} years old#{(rand < 0.5) ? (', ' + query.user[:nickname]) : nil}.") if seek == 'age'

        ky = seek.gsub(" ", "_").to_sym
        ky = :phone if ky == :number

        if query.user[ky]
          return_data(u[ky])
          DismalTony::HandledResponse.finish("~e:#{moj} Their #{seek} is #{u[ky]}")
        else
          return_data(nil)
          DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know their #{seek}")
        end
      else
        DismalTony::HandledResponse.finish("~e:frown I'm not quite sure how to answer that.")
      end
    end
  end
end