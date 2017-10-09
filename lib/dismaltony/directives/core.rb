module DismalTony::Directives
	class SendTextMessageDirective < DismalTony::Directive
		set_name :send_text
		set_group :core
		
		add_param :sendto


		add_criteria do |qry|
			qry << must { |q| q.verb =~ /send/i || q.root =~ /text/i }
			qry << should { |q| q.children_of(q.verb).include? { |w| w.pos == 'NUM' } }
		end

		def run
			parameters[:sendto] = query.children_of(query.verb).select { |w| w.pos == 'NUM'}.first
			if parameters[:sendto].nil?
				parameters[:sendto] = if query.children_of(query.verb).first =~ /me/i
					query.user['phone_number']
				else
					# Code for if it's a name
				end
			else
				if !parameters[:sendto] =~ /\d{10}/
					HandledResponse.finish("~e:frown That isn't a valid phone number!") 
				end
			end

			

		end
	end
end