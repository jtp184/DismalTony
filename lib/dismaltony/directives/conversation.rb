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