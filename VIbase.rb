require_relative 'ConversationState'

class VIBase
	attr_accessor :name
	attr_accessor :interface
	attr_accessor :emotes
	attr_accessor :handlers

	def initialize(the_name = "Tony", the_interface = ConsoleInterface.new)
		@name = the_name
		@interface = the_interface
		@emotes = {'smile' => '🙂','frown' => '🙁','angry' => '😡','cheeky' => '😜','worried' => '🤕','think' => '🤔','sly' => '😏','cool' => '😎','wink' => '😉'}
		@handlers = []
		self.load_handlers
	end

	def identify_user
	end

	def list_handlers
		response_string = "Okay, I can do:\n"
		@handlers.each do |handler|
			the_name = handler.new().handler_name
			response_string += "	#{the_name}\n"
		end
		say response_string
	end

	def load_handlers
		found_files = (Dir.entries "#{Dir.pwd}/handlers/").reject { |e|  !(e =~ /.+\.rb/)}
		found_files.each do |file|
			load "#{Dir.pwd}/handlers/#{(File.basename(file))}"
		end
		QueryHandler.list.each do |handler|
			@handlers << handler
		end
	end

	def query!
		self.handlers.each do |handler_class|
			handler = handler_class.new()
			if handler.responds? str
				handler.activate_handler! str
			else
			end
		end
	end

	def query str
		self.handlers.each do |handler_class|
			handler = handler_class.new()
			if handler.responds? str
				self.say handler.activate_handler str
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