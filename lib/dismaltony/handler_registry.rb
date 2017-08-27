module DismalTony # :nodoc:
  # Central registry for query handlers. Calling DismalTony.create_handler adds the handler you create to this registry.
  class HandlerRegistry
    include Enumerable
    # The array of QueryHandler objects
    @handlers = [DismalTony::ExplainHandler]

    # Calls <tt>load</tt> on all *.rb files in +directory+
    def self.load_handlers_from(directory)
      found_files = (Dir.entries directory).select { |filname| filname =~ /.+\.rb/ }
      found_files.each do |file|
        load "#{directory}/#{File.basename(file)}"
      end
    end

    # Syntactic sugar, serves the same function as HandlerRegistry.load_handlers_from and loads all handler files in +dir+
    def self.load_handlers!(dir = '/')
      load_handlers_from(dir)
    end

    # Attribute reader for the handlers class variable.
    class << self
      attr_reader :handlers #:nodoc:
    end

    # Adds the QueryHandler +handler+ to HandlerRegistry.handlers
    def self.register(handler)
      @handlers << handler
    end

    # Syntactic sugar. Calls the method on HandlerRegistry.handlers
    def self.each(&block)
      handlers.each(&block)
    end

    # Returns an array of QueryHandler objects whose name matches +par+
    def self.[](par)
      par = Regexp.new(par, Regexp::IGNORECASE) if par.is_a? String
      handlers.select { |hand| hand.new(DismalTony::VIBase.new).handler_name =~ par }
    end

    # Returns an array of QueryHandler objects whose group (if one exists) matches +par+
    def self.group(par)
      handlers.select { |hand| hand.group == nil } if par == 'none'
      handlers.select { |hand| hand.group == par }
    end

    # Returns an Array of the names of distinct groups Handlers are in. If a handler doesn't have a group, it is filed with 'none'
    def self.groups
      (handlers.map { |hand| ( hand.group || 'none') }).uniq
    end
  end
end
