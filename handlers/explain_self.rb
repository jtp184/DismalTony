DismalTony.create_handler do
	@handler_name = 'explain-self'
	@patterns = [/what (?:are you|is your purpose|are you for|are you designed to do|do you do)\??/i]

	def activate_handler(query, user); end

	def activate_handler!(query, user); end
end
