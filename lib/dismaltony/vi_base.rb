module DismalTony # :nodoc:
  # The essential class. A VI, or Virtual Intelligence,
  # forms the basis for the DismalTony gem, and is your conversational agents for handling queries
  class VIBase
    # The name of the Intelligence
    attr_reader :name
    # A DialogInterface object representing where to route the VI's speech
    attr_reader :return_interface
    # An Array of QueryHandler objects that the VI can use
    attr_reader :handlers
    # A DataStorage object representing the VI's memory and userspace
    attr_reader :data_store

    # Options for +opts+
    # * +:name+ - The name for the VI. Defaults to 'Tony'
    # * +:handlers+ - The Array of handlers. Defaults to the entire contents of the HandlerRegistry.
    # * +:data_store+ - The data store to use with this VI. Defaults to a generic DataStorage object.
    # * +:return_interface+ - The interface to route conversation back through. Defaults to the ConsoleInterface.
    def initialize(**opts)
      @name = (opts[:name] || 'Tony'.freeze)
      @return_interface = (opts[:return_interface] || DismalTony::ConsoleInterface.new(self))
      @handlers = (opts[:handlers] || DismalTony::HandlerRegistry.handlers)
      @data_store = (opts[:data_store] || DismalTony::DataStorage.new)
    end

    # Returns an Array of strings corresponding to the +handler_name+ of all the handlers loaded.
    def list_handlers
      @handlers.map { |handler| handler.new(self).handler_name.to_s }
    end

    # * +str+ - the Query to resolve.
    # * +user_identity+ - a UserIdentity object corresponding to the user making the query. Defaults to UserIdentity::DEFAULT
    #
    #
    # The primary method. Uses any available handler to handle a query, calls QueryHandler.activate_handler! and returns a HandledResponse object.
    #
    # * First, it checks if the ConversationState indicates that we're resuming.
    # * * If so, it uses the information in that to handle the query by calling ConversationState.return_to_handler and passing the query.
    # * If we aren't resuming, it checks to see if any known handler matches the query via the QueryHandler.responds? method.
    # * * If so, it uses that one, passing along the executing to the handler.
    # * * Otherwise, it will return a HandledResponse.error object.
    # * * Unless the HandledResponse.format has <tt>:quiet => true</tt>, VIBase.say will be called on the HandledResponse.return_message attribute.
    def query!(str = '', user_identity = DismalTony::UserIdentity::DEFAULT)
      responded = []
      user_cs = user_identity.conversation_state
      post_handled = DismalTony::HandledResponse.new

      if ret = user_cs.return_to_handler
        handle = (@handlers.select { |hand| hand.new(self).handler_name == ret.to_s }).first.new(self)
        handle.data = user_cs.data_packet
        post_handled = if ret == 'index'
                         handle.activate_handler! str, user_identity
                       else
                         ret_method = user_cs.return_to_method
                         post_handled = if handle.respond_to? ret_method
                                          if user_cs.return_to_args
                                            handle.method(ret_method.to_sym).call(user_cs.return_to_args.split(', ') + [str, user_identity])
                                          else
                                            handle.method(ret_method.to_sym).call(str, user_identity)
                                          end
                                        else
                                          DismalTony::HandledResponse.finish "~e:frown I'm sorry, there appears to be a problem with that program"
                         end
        end
      else
        @handlers.each do |handler_class|
          handler = handler_class.new(self)
          responded << handler if handler.responds? str
        end
        post_handled = if responded.empty?
                         DismalTony::HandledResponse.error
                       elsif responded.length == 1
                         responded.first.activate_handler! str, user_identity
                       elsif responded.any? { |hand| hand.handler_name = 'explain-handler' }
                         (responded.select { |hand| hand.handler_name = 'explain-handler' }).first.activate_handler! str, user_identity
                       else
                         responded.first.activate_handler! str, user_identity
       end
    end
      say_opts(@return_interface, post_handled.to_s, post_handled.format) unless post_handled.format[:quiet]
      post_handled.conversation_state.from_h(user_identity: user_identity, last_recieved_time: Time.now)
      user_identity.modify_state!(post_handled.conversation_state)
      @data_store.on_query(post_handled)
      post_handled
  end

    # calls QueryResult#query_result for +str+ and +user_identity+
    def query_result(str, user_identity = DismalTony::UserIdentity::DEFAULT)
      @handlers.each do |handler_class|
        handler = handler_class.new(self)
        if handler.responds?(str) && handler.respond_to?('query_result')
          return handler.query_result str, user_identity
        end
      end
      nil
    end

    # Soft query. Searches the handlers for a query that matches +str+, and calls QueryHandler.activate_handler on it for +user_identity+
    def query(str, user_identity)
      responded = []

      handlers.each do |handler_class|
        handler = handler_class.new(self)
        responded << handler if handler.responds? str
      end

      DismalTony::HandledResponse.error unless responded.length == 1
      DismalTony::HandledResponse.finish(responded.first.activate_handler(str, user_identity))
    end

    # For internal use, handles a query silently and grants access to handlers inside other handlers or programs.
    #
    # * +qry+ - Used to match against QueryHandler.handler_name
    # * +usr+ - a UserIdentity object representing the user. Defaults to UserIdentity::DEFAULT
    # * +args+ - Optional parameter. Sets the QueryHandler.data of the handler manually
    def quick_handle(qry = '', usr = DismalTony::UserIdentity::DEFAULT, args = {})
      use_handler = @handlers.select { |handler| handler.new(self).handler_name == qry }
      return DismalTony::HandledResponse.new("I'm sorry! I couldn't find that handler", nil) if use_handler.nil?
      handle = use_handler.first.new(self)
      handle.data = args
      handle.activate_handler! qry, usr
    end

    # Sends the message +str+ back through the DialogInterface +interface+, after calling Formatter::Printer.format on it.
    def say_through(interface, str)
      interface.send(Formatter::Printer.format(str, {}))
    end

    # Sends the message +str+ back through the DialogInterface +interface+, after calling Formatter::Printer.format on it, with the options +opts+
    def say_opts(interface, str, opts)
      interface.send(Formatter::Printer.format(str, opts))
    end

    # Simplest dialog function. Sends the message +str+ back through VIBase.return_interface
    def say(str)
      @return_interface.send(Formatter::Printer.format(str))
    end

    # Method for using SubHandler type handlers.
    #
    # * +subject+ - The used to match against SubHandler.handler_name
    # * +verb+ - The name of the method to use. Casts to a Symbol before being used.
    # * +params+ - Optional. Passed in to the handler's action as its arguments
    def control(subject, verb, params = {})
      the_remote = (@handlers.select { |r| r.new(self).handler_name == subject })
      return DismalTony::HandledResponse.finish("Sorry, that didn't work!") if the_remote.nil?
      the_remote = the_remote.first.new(self)
      begin
        the_method = the_remote.method(verb.to_sym)
        if params == {}
          the_method.call
        else
          the_method.call(params)
        end
      rescue NameError
        DismalTony::HandledResponse.finish("Sorry, that didn't work!")
      end
    end
  end
end
