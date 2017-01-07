require 'json'

module Tony
	class VIBase
		attr_accessor :name
		attr_accessor :return_interface
		attr_accessor :emotes
		attr_accessor :handlers

		def initialize(the_name = "Tony", the_interface = Tony::ConsoleInterface.new)
			@name = the_name
			@return_interface = the_interface
			@emotes = Tony::EmojiDictionary.new.to_h
			@handler_directory = "/"
			@handlers = []
		end
		# self.load_handlers

		def identify_user
		end

		def list_handlers			
			return @handlers.map { |e| e.new.handler_name.to_s }
		end

		def load_handlers_from directory
			found_files = (Dir.entries directory).reject { |e|  !(e =~ /.+\.rb/)}
			found_files.each do |file|
				load "#{directory}/#{(File.basename(file))}"
			end
			Tony::QueryHandler.list.each do |handler|
				@handlers << handler
			end
		end

		def set_handler_dir_to directory
			@handler_directory = directory
		end

		def load_handlers
			load_handlers_from @handler_directory
		end

		def query! str
			responded = []
			response = nil

			@handlers.each do |handler_class|
				handler = handler_class.new
				if handler.responds? str
					responded << handler
					# puts "handled by #{handler.handler_name}"
				else
				end
			end

			if responded.length == 0
				self.say("~e:frown I'm sorry, I didn't understand that!")
			elsif responded.length == 1
				resp = responded.first.activate_handler! str, self
				self.say(resp.to_s)
			else

				if (responded.count {|e| e.handler_name.eql? "explain-handler"}) > 0
					ExplainHandler.new.activate_handler! str, self
				else
					puts print responded
					responded.first.activate_handler! str, self
				end
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
			responded = []
			response = nil
			self.handlers.each do |handler_class|
				handler = handler_class.new()
				if handler.responds? str
					responded << handler
				else
				end
			end
			if responded.length == 1
				resp = responded.first.activate_handler str, self
				self.say(resp.to_s)
			elsif responded.length == 0
				self.say("~e:frown I'm sorry, I didn't understand that!")
			else
				responded.first.activate_handler str, self
			end
		end

		def quick_handle (name = "", args = {})
			use_handler = nil

			@handlers.each do |h|
				if(h.new.handler_name.eql? name)
					use_handler = h
				end
			end

			handle = use_handler.new
			handle.data = args

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
end