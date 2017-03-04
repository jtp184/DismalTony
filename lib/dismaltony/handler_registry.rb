module DismalTony
	class HandlerRegistry
		include Enumerable
		@@handlers = []

		def self.load_handlers_from(directory)
			found_files = (Dir.entries directory).reject { |e| !(e =~ /.+\.rb/) }
			found_files.each do |file|
				load "#{directory}/#{File.basename(file)}"
			end
		end

		def self.load_handlers!(dir = '/')
			self.load_handlers_from(dir)
		end

		def self.handlers
			@@handlers
		end

		def self.register(handler)
			@@handlers << handler
		end

		def self.each()
			@@handlers.each
		end

		def self.[](par)
			par = Regexp.new(par, Regexp::IGNORECASE) if par.is_a? String
			@@handlers.select { |h| h.handler_name =~ par}
		end

		def self.group(par)
			@@handlers.select do |h| 
				next unless h.responds_to?('group')
				h.group == par
			end
		end

		def self.groups
			(@@handlers.map { |h| (h.group if h.responds_to('group')) || ("none")}).uniq
		end

	end
end