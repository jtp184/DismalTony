module DismalTony::Directives
	class GreetingDirective < DismalTony::Directive
		set_name :hello
		set_group :fun

		add_criteria do |qry|
			qry << must { |q| q.contains?(/hello/i) || q.contains?(/greetings/i) }
			qry << should { |q| !q['rel', 'discourse'].empty?}
			qry << should { |q| !q['xpos', 'UH'].empty?}
		end

		def run
			if query =~ /how are you/i
				DismalTony::HandledResponse.finish("~e:thumbsup I'm doing well!")
			else
				DismalTony::HandledResponse.finish([
					'~e:wave Hello!',
					'~e:smile Greetings!',
					'~e:rocket Hi!',
					"~e:star Hello, #{query.user['nickname']}!",
					'~e:snake Greetings!',
					'~e:cat Hi!',
					"~e:octo Greetings, #{query.user['nickname']}!",
					'~e:spaceinvader Hello!'
					].sample)
			end
		end
	end
	
	class InteractiveSignupDirective < DismalTony::Directive
		set_name :interactivesignup
		set_group :conversation

		add_param :user_id
		add_param :send_number

		add_criteria do |qry|
			qry << must { |q| q }
		end

		def return_cs
			cs = DismalTony::ConversationState.new(
				next_directive: self,
				next_method: :get_name,
				parse_next: false
				)
		end

		def get_last_name
			
		end

		def get_name
			if query.raw_text =~ /\s/
				parameters[:user_id][:first_name] = query.raw_text.split(' ')[0]
				parameters[:user_id][:last_name] = query.raw_text.split(' ')[1]

				parameters[:user_id][:nickname] = parameters[:user_id][:first_name]
			else
			end
		end

		def run
			parameters[:send_number] = query['xpos', 'NUM'].first
			ncs = query.previous_state.clone
			ncs.merge(return_cs)
			parameters[:user_id] = DismalTony::UserIdentity.new(
				user_data: { phone: parameters[:send_number] },
				conversation_state: ncs
				)
		end
	end
end

