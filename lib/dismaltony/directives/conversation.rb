module DismalTony::Directives
	class GreetingDirective < DismalTony::Directive
		set_name :hello
		set_group :conversation

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
			qry << must { |q| q.contains?(/invit(e|ation)/i, /join/i, /send/i)}
			qry << should { |q| !q['pos', 'NUM'].empty? }
		end

		def welcome_msg
			moj = ['exclamationmark', 'present', 'scroll', 'speechbubble', 'wave', 'envelopearrow'].sample
			"~e:#{moj} Hello! I'm #{vi.name}, a Virtual Intelligence. What is your name?"
		end

		def finish_msg
			moj = ['wave', 'smile', 'envelopeheart', 'checkbox', 'thumbsup', 'star', 'toast'].sample
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
			parameters[:user_id][:last_name] = query.raw_text
			DismalTony::HandledResponse.finish(finish_msg)
		end

		def get_name
			if query.raw_text =~ /\s/
				parameters[:user_id][:first_name] = query.raw_text.split(' ')[0]
				parameters[:user_id][:last_name] = query.raw_text.split(' ')[1]

				parameters[:user_id][:nickname] = parameters[:user_id][:first_name]
				
				vi.data_store.new_user(user_data: parameters[:user_id].user_data)

				DismalTony::HandledResponse.finish(finish_msg)
			else
				parameters[:user_id][:first_name] = query.raw_text
				parameters[:user_id][:nickname] = parameters[:user_id][:first_name]
				DismalTony::HandledResponse.then_do(directive: self, method: :get_last_name, data: self.parameters, parse_next: false, message: "Okay! And what is your last name?")
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
			vi.say_through(DismalTony::SMSInterface.new(parameters[:send_number]), welcome_msg)
			DismalTony::HandledResponse.finish("~e:thumbsup Okay! I sent the message to #{parameters[:send_number]}")
		end
	end
end

