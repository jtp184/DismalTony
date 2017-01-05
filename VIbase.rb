require_relative 'ConversationState'
require 'json'

class VIBase
	attr_accessor :name
	attr_accessor :return_interface
	attr_accessor :emotes
	attr_accessor :handlers

	def initialize(the_name = "Tony", the_interface = ConsoleInterface.new)
		@name = the_name
		@return_interface = the_interface
		@emotes = JSON.load File.readlines("emojidictionary.json").join("\n")
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

	def query! str
		resp = nil
		self.handlers.each do |handler_class|
			handler = handler_class.new()
			if handler.responds? str
				resp = handler.activate_handler! str, self
			else
			end
		end
		if resp.nil?
		else
			self.say(resp.return_message)
		end
	end

	def info_query str
		self.handlers.each do |handler_class|
			handler = handler_class.new()
			if handler.responds? str and handler.responds_to? "info_handler"
				return handler.info_handler str, self
			else
			end
		end
	end

	def query str
		self.handlers.each do |handler_class|
			handler = handler_class.new()
			if handler.responds? str
				self.say handler.activate_handler str, self
			else
			end
		end
	end

	def say_through interface, str
		pat = /(?:~e:(?<emote>\w+\b) )?(?<message>.+)/
		md = pat.match str
		if str =~ pat
			if md["emote"].nil?
				interface.send(response(md["message"], 'smile'))
			else
				interface.send(response(md["message"], md["emote"]))
			end
		end	
	end

	def say str
		pat = /(?:~e:(?<emote>\w+\b) )?(?<message>.+)/
		md = pat.match str
		if str =~ pat
			if md["emote"].nil?
				@return_interface.send(response(md["message"], 'smile'))
			else
				@return_interface.send(response(md["message"], md["emote"]))
			end
		end
	end

	def response str, emo
		return "[#{@emotes[emo]}]" + ": #{str}"
	end
end