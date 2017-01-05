require_relative 'ConversationState'
require_relative 'HandledResponse'

class QueryHandler
	attr_accessor :handler_name
	attr_accessor :patterns
	attr_accessor :data

	def initialize()
		@handler_name = ""
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

	def error_out
		return nil
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

		@patterns.each do |pattern|
			next if query.eql? ""
			if (match_data.nil?)
				match_data = pattern.match(query)
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