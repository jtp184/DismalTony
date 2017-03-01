class IdentifyUser < DismalTony::QueryHandler
	def handler_start
		@handler_name = 'learn-user-name'
		@patterns = [/(my name is (?<name>.+)|I am (?<name>.+)|call me (?<name>.+))/]
	end

	def activate_handler!(query, user)
		parse query
		user['nickname'] = @data['name']
		DismalTony::HandledResponse.finish("~e:checkbox Okay! I'll call you #{@data['name']} from now on")
	end

	def activate_handler(query, user)
		parse query
		"I will tell you who you are!"
	end
end