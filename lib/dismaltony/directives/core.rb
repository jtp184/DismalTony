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

		def run
			parameters[:sendto] = query['pos', 'NUM'].first&.to_s
			if parameters[:sendto].nil?
				parameters[:sendto] = if query.children_of(query.verb).first =~ /me/i
					query.user['phone_number']
				else
					# Code for if it's a name
				end
			else
				if !parameters[:sendto] =~ /^\d{10}$/
					return DismalTony::HandledResponse.finish("~e:frown That isn't a valid phone number!") 
				end
			end

			parameters[:sendmsg] = query.raw_text.split(query['pos', 'VERB'].select { |w| w.any_of?(/says/i, /say/i) }.first.to_s << " ")[1]

			vi.say_through(DismalTony::SMSInterface.new(parameters[:sendto]), parameters[:sendmsg])
			DismalTony::HandledResponse.finish("~e:speechbubble Okay! I sent the message.")
		end
	end
end