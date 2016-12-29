class QueryHandler
	attr_accessor :handler_name
	attr_accessor :verbs
	attr_accessor :patterns
	attr_accessor :data

	def initialize()
		@handler_name = ""
		@verbs = []
		@patterns = []
		@data = {}
	end

	class << self
		attr_reader :list
	end
	@list = []

	def self.inherited(klass)
		@list << klass
	end

	def activate_handler!
	end

	def activate_handler
	end

	def check_understanding query
		parse query
		response = "Okay, I got:\n\n"
		@data.keys.each do |key|
			response += "	#{key}: #{@data[key]}\n"
		end
		return response
	end

	def responds? query
		return parse(query)
	end

	def parse query
		match_data = nil

		@verbs.each_with_index do |verb, pattern_index|
			next if query.eql? ""
			if query.downcase.include? verb
				match_data = @patterns[pattern_index].match(query)
			else
			end
		end
		if match_data.nil?

		else
			@data.keys.each do |key|
				@data[key] = match_data[key]
			end
		end

		return !(match_data.nil?)
	end

	def register_verbs
		# TODO: Add all verbs to a registry to prevent collisions
		self.verbs.each do |verb|
			# Register Verb
		end
	end

	# def from_json!(json_string)
	# 	hashed = JSON.parse(json_string)
	# 	self.handler_name = hashed["handler_name"]
	# 	self.verbs = hashed["verbs"]
	# 	# self.register_verbs
	# 	self.patterns = hashed["patterns"]
	# 	self.patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
	# 	self.data = (unpack_data hashed["data"])
	# 	return self
	# end
end