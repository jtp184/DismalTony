DismalTony.create_handler do
	def handler_start
		@handler_name = 'get-temperature'
		@patterns = [/how (?:hot|cold) is it (?:at|in) (?<location>[\w ]+)\??/i,/what is the temp(?:erature)? (?:at|in) (?<location>[\w ]+)\??/i]
	end

	def activate_handler(query, user)
		parse query
		"I'll tell you the temperature in #{@data['location']}"
	end

	def query_result
	end

	def activate_handler!(query, user)
		parse query
		@vi.use_service(
			'weather',
			'get_current_temp',
			q: @data['location']
			)
	end
end