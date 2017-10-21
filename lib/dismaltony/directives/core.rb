module DismalTony::Directives
	class SendTextMessageDirective < DismalTony::Directive
		set_name :send_text
		set_group :core
		
		add_param :sendto
		add_param :sendmsg

		add_criteria do |qry|
			qry << must { |q| q.verb =~ /send/i || q.root =~ /text/i }
			qry << should { |q| q.children_of(q.verb).any? { |w| w.pos == 'NUM' } }
		end

		def get_tel
			parameters[:sendto] = query.raw_text
			DismalTony::HandledResponse.then_do(directive: self, method: :get_msg, message: "~e:speechbubble Okay, what shall I say to them?", parse_next: false, data: parameters)
		end

		def get_msg
			parameters[:sendmsg] = query.raw_text
			vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
			DismalTony::HandledResponse.finish("~e:speechbubble Okay! I sent the message.")
		end

		def run
			parameters[:sendto] = query['pos', 'NUM'].first&.to_s
			if parameters[:sendto].nil?
				parameters[:sendto] = if query.children_of(query.verb)&.first =~ /^me$/i
																query.user[:phone_number]
														elsif query.children_of(query.verb)&.first =~ /[a-z]/i
															# Code for if it's a name
														else
															# If it's really nonexistent
														end
			else
				if (parameters[:sendto] =~ /^\d{10}$/) == nil
					return DismalTony::HandledResponse.finish("~e:frown That isn't a valid phone number!") 
				end
			end

			return DismalTony::HandledResponse.then_do(directive: self, method: :get_tel, message: "~e:pound Okay, to what number should I send the message?", parse_next: false, data: parameters) if parameters[:sendto].nil?
			parameters[:sendmsg] = query.raw_text.split(query['pos', 'VERB'].select { |w| w.any_of?(/says/i, /say/i) }.first.to_s << " ")[1]

			vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
			DismalTony::HandledResponse.finish("~e:thumbsup Okay! I sent the message.")
		end
	end

	class UserInfoDirective < DismalTony::Directive
		set_name :whoami
		set_group :info

		add_criteria do |qry|
			qry << must { |q| q.contains?(/who/i, /what/i) }
			qry << must { |q| q.contains?(/i/i, /my/i) }
			qry << should { |q| q.contains?(/is/i, /are/i, /am/i)}
		end

		def run
			if query =~ /who am i/i
				moj = ['think','magnifyingglass','crystalball','smile'].sample
				DismalTony::HandledResponse.finish("~e:#{moj} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}.")
			elsif query =~ /what('| i)?s my/i
				seek = query.children_of(query.root).select { |w| w.rel == 'nsubj' }&.first
				
				moj = case seek.to_s
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
					['magnifyingglass', 'key'].sample
				end

				return DismalTony::HandledResponse.finish("~e:#{moj} You're #{query.user[:nickname]}! #{query.user[:first_name]} #{query.user[:last_name]}.") if (seek.to_s == 'name')
				return DismalTony::HandledResponse.finish("~e:#{moj} You are #{Duration.new(Time.now - j[:birthday]).weeks / 52} years old, #{query.user[:nickname]}!") if (seek.to_s == 'age')

				ky = seek.to_s.to_sym
				ky = :phone if ky == :number

				if query.user[ky]
					DismalTony::HandledResponse.finish("~e:#{moj} Your #{seek.to_s} is #{query.user[ky]}")
				else
					DismalTony::HandledResponse.finish("~e:frown I'm sorry, I don't know your #{seek.to_s}")
				end
			else
				DismalTony::HandledResponse.finish("~e:frown I'm not quite sure how to answer that.")
			end
		end
	end

	class SelfDiagnosticDirective < DismalTony::Directive
		set_name :selfdiagnostic
		set_group :debug

		add_criteria do |qry|
			qry << must { |q| q =~ /diagnostic/i }
			qry << must { |q| q.verb.any_of?(/run/i, /execute/i, /perform/i) }
		end

		def run
			begin
				good_moj = ['tophat', 'thumbsup', 'star', 'checkbox', 'chartup'].sample
				str = ParseyParse.('Diagnostic successful').to_s
				str << ". I am #{vi.name}! "
				str << "I have #{DismalTony::Directives.all.length} Directives"
				str << ", and it is #{Time.now.strftime('%I:%M%p')} where I am."
				DismalTony::HandledResponse.finish("~e:#{good_moj} #{str}")
			rescue
				bad_moj = ['cancel','caution', 'alarmbell', 'thumbsdown', 'thermometer', 'worried'].sample
				return DismalTony::HandledResponse.finish("~e:#{bad_moj} Something went wrong!")
			end
		end
	end
end