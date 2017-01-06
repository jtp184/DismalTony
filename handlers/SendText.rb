class SendText < QueryHandler
	def initialize()
		@handler_name = "send-text"
		@patterns = ["\\b(?:(?:send a? ?(?:message|text))|(?:message|text))\\s?(?:to)?\\s?(?<destination>\d{10}|(?:\\w| )+) (?:saying|that says) (?<message>.+)"].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
		@data = {"destination" => "", "message" => ""}
	end

	def lookup_name str
		# TODO: integrate with address book
	end

	def format_number str
		return "+1" + str
	end

	def activate_handler! query, vi
		parse query

		if /\d+/.match(@data["destination"])
			vi.say_through(SMSInterface.new(@data["destination"]), @data["message"])
		else
			error_out
		end

		return HandledResponse.new("Okay! I sent your message.", nil)
	end

	def explain
	end

	def activate_handler query, vi
		parse query
		return "I will message #{@data["destination"]} and say \"#{@data["message"]}\""
	end
end