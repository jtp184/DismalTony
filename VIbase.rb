class VIBase
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