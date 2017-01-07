class ExplainHandler < Tony::QueryHandler
	def initialize()
		@handler_name = "explain-handler"
		@patterns = ["^what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)"].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
		@data = {"second_query" => ""}
	end

	def activate_handler! query, vi
		parse query
		second_result = vi.query(""+@data['second_query'])
		return Tony::HandledResponse.new("#{second_result}", nil)
	end

	def activate_handler query, vi
		parse query
		return "I will explain what I'd do if you asked me \"#{@data['second_query']}\""
	end
end