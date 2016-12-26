class QueryHandler
	attr_accessor :handler_name
	attr_accessor :verbs
	attr_accessor :patterns
	attr_accessor :data

	def initialize (my_name = "", my_verbs = [], my_patterns = [], my_data = [])
		self.handler_name = my_name
		self.verbs = my_verbs
		# self.register_verbs
		self.patterns = my_patterns
		self.patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
		self.data = {}
		my_data.each do |key|
			self.data[key] = ""
		end

	end

	def create (my_name = "", my_verbs = [], my_patterns = [], my_data = [])
		return QueryHandler.new(my_name, my_verbs, my_patterns, my_data)
	end

	def activate_handler!
	end

	def activate_handler
	end

	def check_understanding query
		parse query
		response = "Okay, I got:\n\n"
		data.keys.each do |key|
			response += "	#{key}: #{data[key]}\n"
		end
		return response
	end

	def responds? query
		self.verbs.each do |verb|
			if query.downcase.include? verb
				return true
			else
			end
		end
	end

	def parse query
		match_data = nil
		self.verbs.each_with_index do |verb, pattern_index|
			if query.downcase.include? verb
				match_data = self.patterns[pattern_index].match query
			else
			end
		end
		if match_data.nil?

		else
			self.data.keys.each do |key|
				self.data[key] = match_data[key]
			end
		end
	end

	def register_verbs
		# TODO: Add all verbs to a registry to prevent collisions
		self.verbs.each do |verb|
			# Register Verb
		end
	end

	def from_json!(json_string)
		hashed = JSON.parse(json_string)
		self.handler_name = hashed["handler_name"]
		self.verbs = hashed["verbs"]
		# self.register_verbs
		self.patterns = hashed["patterns"]
		self.patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
		self.data = (unpack_data hashed["data"])
		return self
	end
end