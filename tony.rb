require 'twilio-ruby'
# require 'sinatra'

class QueryHandler
	attr_accessor :handler_name
	attr_accessor :verbs
	attr_accessor :patterns
	attr_accessor :data

	def export
		hash = {}
		self.instance_variables.each do |var|
			hash["#{var[1,var.length-1]}"] = (self.instance_variable_get var).to_s
		end
		return hash
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

class SMSInterface
	attr_accessor :client
	attr_accessor :destination
	
	def initialize()
		twilio_account_sid = 'AC6188347d1562eb480eec4771f7628f9a'
		twilio_auth_token = '7b56edc33f1e667929607257056b37eb'
		@client = Twilio::REST::Client.new twilio_account_sid, twilio_auth_token 
	end

	def send msg
		@client.account.messages.create(
			from: '+13476258669',
			to: self.destination,
			body: msg
			)
	end
end

class SysIO
	def send msg
		puts msg
	end

	def recieve 
		return gets
	end
end

class AIBase
	attr_accessor :name
	attr_accessor :interface
	attr_accessor :emotes
	attr_accessor :handlers

	def initialize()
		@emotes = {'smile' => '🙂','frown' => '🙁','angry' => '😡','cheeky' => '😜','worried' => '🤕','think' => '🤔','sly' => '😏','cool' => '😎','wink' => '😉'}
		@handlers = []
	end

	def list_handlers
		response_string = "Okay, I can do:\n"
		self.handlers.each do |handler|
			the_name = handler.handler_name
			response_string += "	#{the_name}\n"
		end
		say response_string
	end

	def load_handlers
		q = QueryHandler.new()
		found_files = (Dir.entries "#{Dir.pwd}/handlers/").reject { |e|  !(e =~ /.+\.json/)}
		found_files.each do |file|
			self.handlers << q.from_json(File.readlines("#{Dir.pwd}/handlers/" + file).join("\n"))
		end
	end

	def query str
		self.handlers.each do |handler|
			if handler.responds? str
				self.say handler.check_understanding str
			else
			end
		end
	end

	def say_emote str, emo
		interface.send(response(str, emo))		
	end

	def say str
		interface.send(response(str, 'smile'))
	end

	def response str, emo
		return "[#{@emotes[emo]}]" + ": #{str}"
	end
end

tony = AIBase.new()
tony.name = "tony"
# tony.interface = SMSInterface.new()
tony.interface = SysIO.new()
# tony.interface.destination = '+18186209630'
tony.load_handlers
# tony.query ""
tony.list_handlers
# tony.query "list people on friday lunch"
# while loop
# 	tony.query
# end