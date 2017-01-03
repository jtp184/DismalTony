class SendText < QueryHandler
	def initialize()
		@handler_name = "send-text"
		@verbs = ["send", "text", "message"]
		@patterns = (Array.new(3) {"(?:(?:send a? ?(?:message|text))|(?:message|text))\\s?(?:to)?\\s?(?<destination>\d{10}|(?:\\w| )+) (?:saying|that says) (?<message>.+)"}).map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
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
		
		stashed_interface = vi.interface
		vi.interface = SMSInterface.new()
		if /\d+/.match(@data["destination"])
			vi.interface.destination = @data["destination"]
			vi.say(@data["message"])
		else
			error_out
		end
		vi.interface = stashed_interface
	end

	def activate_handler query, vi
		parse query
		return "I will message #{@data["destination"]} and say \"#{@data["message"]}\""
	end
end