class ExplainHandler < QueryHandler
	def initialize()
		@handler_name = "explain-handler"
		@patterns = ["\\bwhat (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)"].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
		@data = {"second_query" => ""}
	end

	def activate_handler! query, vi
		parse query
		second_result = vi.query(""+@data['second_query'])
		return HandledResponse.new("", nil)
	end

	def activate_handler query, vi
		parse query
		return "I will explain what I'd do if you asked me \"#{@data['second_query']}\""
	end
end