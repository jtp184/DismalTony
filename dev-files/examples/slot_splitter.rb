require 'json'

class QueryHandler
	attr_accessor :handler_name
	attr_accessor :verbs
	attr_accessor :patterns
	attr_accessor :data

	def check_understanding query
		parse query
		response = "Okay, I got:\n\n"
		data.keys.each do |key|
			response += "	#{key}: #{data[key]}\n"
		end
		return response
	end

	def parse query
		match_data = nil

		self.verbs.each_with_index do |verb, pattern_index|
			if query.downcase.include? verb
				match_data = self.patterns[pattern_index].match query
			else
			end
		end

		self.data.keys.each do |key|
			self.data[key] = match_data[key]
		end
	end

	def register_verbs
		# TODO: Add all verbs to a registry to prevent collisions
		self.verbs.each do |verb|
			# Register Verb
		end
	end

	def from_json(json_string)

		new_object = QueryHandler.new()

		hashed = JSON.parse(json_string)
		new_object.handler_name = hashed["handler_name"]
		new_object.verbs = hashed["verbs"]
		# new_object.register_verbs
		new_object.patterns = hashed["patterns"]
		new_object.patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }

		new_object.data = unpack_data hashed["data"]

		return new_object
	end

	def unpack_data(data)
		resolved = Hash.new()
		data.each do |member|
			k = member["key"]
			case member["type"]
			when "string"
				resolved[k] = ""
			when "number"
				resolved[k] = 0
			else
			end
		end
		return resolved
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

handle = QueryHandler.new()
handle.from_json!(File.readlines("ex_handler.json").join("\n"))

puts handle.check_understanding "put mario on friday afternoon"