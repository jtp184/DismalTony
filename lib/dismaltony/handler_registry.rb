module DismalTony # :nodoc:
  # Central registry for handlers. Calling DismalTony.create_handler adds the handler you create to this registry.
  class HandlerRegistry
    include Enumerable
    # The array of QueryHandler objects
    @handlers = [DismalTony::ExplainHandler]

    # Calls <tt>load</tt> on all *.rb files in +directory+
    def self.load_handlers_from(directory)
      found_files = (Dir.entries directory).select { |e| e =~ /.+\.rb/ }
      found_files.each do |file|
        load "#{directory}/#{File.basename(file)}"
      end
    end

    # Syntactic sugar, serves the same function as HandlerRegistry.load_handlers_from and loads all handler files in +dir+
    def self.load_handlers!(dir = '/')
      load_handlers_from(dir)
    end

    # Attribute reader for the handlers class variable.
    def self.handlers
      @handlers
    end

    # Adds the QueryHandler +handler+ to HandlerRegistry.handlers
    def self.register(handler)
      @handlers << handler
    end

    # Syntactic sugar. Calls the method on HandlerRegistry.handlers
    def self.each
      @handlers.each
    end

    # Returns an array of QueryHandler objects whose name matches +par+
    def self.[](par)
      par = Regexp.new(par, Regexp::IGNORECASE) if par.is_a? String
      @handlers.select { |h| h.new(DismalTony::VIBase.new).handler_name =~ par }
    end

    # Returns an array of QueryHandler objects whose group (if one exists) matches +par+
    def self.group(par)
      (@handlers.map { |e| e.new(DismalTony::VIBase.new) }).select do |h|
        next unless h.responds_to?('group')
        h.group == par
      end
    end

    # Returns an Array of the names of distinct groups Handlers are in. If a handler doesn't have a group, it is filed with 'none'
    def self.groups
      ((@handlers.map { |e| e.new(DismalTony::VIBase.new) }).map { |h| (h.group if h.responds_to('group')) || 'none' }).uniq
    end
  end
end
