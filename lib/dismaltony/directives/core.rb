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
			DismalTony::HandledResponse.then_do(directive: self, method: :get_msg, message: "~e:pound Okay, what shall I say to them?", parse_next: false, data: parameters)
		end

		def get_msg
			parameters[:sendmsg] = query.raw_text
			vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
			DismalTony::HandledResponse.finish("~e:speechbubble Okay! I sent the message.")
		end

		def run
			parameters[:sendto] = query['pos', 'NUM'].first&.to_s
			if parameters[:sendto].nil?
				parameters[:sendto] = if query.children_of(query.verb).first =~ /^me$/i
					query.user[:phone_number]
				# elsif query.children_of(query.verb).first =~ /[a-z]/i
					# Code for if it's a name
				else
					# If it's really nonexistent
					DismalTony::HandledResponse.then_do(directive: self, method: :get_tel, message: "~e:pound Okay, to what number should I send the message?", parse_next: false, data: parameters)
				end
			else
				if (parameters[:sendto] =~ /^\d{10}$/) == nil
					return DismalTony::HandledResponse.finish("~e:frown That isn't a valid phone number!") 
				end
			end

			parameters[:sendmsg] = query.raw_text.split(query['pos', 'VERB'].select { |w| w.any_of?(/says/i, /say/i) }.first.to_s << " ")[1]

			vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
			DismalTony::HandledResponse.finish("~e:speechbubble Okay! I sent the message.")
		end
	end
end