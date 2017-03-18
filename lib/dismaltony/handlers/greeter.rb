DismalTony.create_handler(DismalTony::CannedResponses) do
	def handler_start
		@handler_name = 'greeter'
		@patterns = ["hello", "hello, #{@vi.name}"]
		@responses = ['~e:wave Hello!', '~e:smile Greetings!', '~e:rocket Hi!', '~e:star Hello!', '~e:snake Greetings!', '~e:cat Hi!', '~e:octo Greetings!', '~e:spaceinvader Hello!']
	end
end