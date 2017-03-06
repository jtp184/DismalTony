module DismalTony
  class VIBase
    attr_accessor :name
    attr_accessor :return_interface
    attr_accessor :emotes
    attr_accessor :handlers
    attr_accessor :data_store

    def initialize(**opts)
      @name = (opts[:name] || "Tony".freeze)
      if opts[:return_interface]
        @return_interface = opts[:return_interface]
      else
        @return_interface = (DismalTony::ConsoleInterface.new(self))
      end
      @handlers = (opts[:handlers] || DismalTony::HandlerRegistry.handlers)
      @data_store = (opts[:data_store] || DismalTony::DataStorage.new)
    end

    def list_handlers
      @handlers.map { |e| e.new(self).handler_name.to_s }
    end

    def query!(str = '', user_identity = DismalTony::UserIdentity.default_user)
      responded = []
      post_handled = DismalTony::HandledResponse.new

      if user_identity.conversation_state.return_to_handler
        handle = (@handlers.select { |h| h.new(self).handler_name == "#{user_identity.conversation_state.return_to_handler}"}).first.new(self)
        handle.data = user_identity.conversation_state.data_packet
        if user_identity.conversation_state.return_to_method == 'index'
          post_handled = handle.activate_handler! str, user_identity
        elsif user_identity.conversation_state.return_to_args
          post_handled = handle.method(user_identity.conversation_state.return_to_method.to_sym).call(user_identity.conversation_state.return_to_args.split(", ") + [str, user_identity])
        else
          post_handled = handle.method(user_identity.conversation_state.return_to_method.to_sym).call(str, user_identity)
        end
      else
        @handlers.each do |handler_class|
          handler = handler_class.new(self)
          responded << handler if handler.responds? str
        end
        if responded.empty?
          post_handled = DismalTony::HandledResponse.error
        elsif responded.length == 1
          post_handled = responded.first.activate_handler! str, user_identity
        elsif responded.any? { |h| h.handler_name = 'explain-handler'}
          post_handled = (responded.select { |h| h.handler_name = 'explain-handler'}).first.activate_handler! str, user_identity
        else
          post_handled = responded.first.activate_handler! str, user_identity
        end
      end

      say_opts @return_interface, post_handled.to_s, post_handled.format unless post_handled.format[:quiet]
      post_handled.conversation_state.from_h! ({:user_identity => user_identity, :last_recieved_time => Time.now})
      user_identity.conversation_state = post_handled.conversation_state
      @data_store.on_query(post_handled)
      return post_handled
    end

    def query_result!(str, user_identity = DismalTony::UserIdentity.default_user)
      @handlers.each do |handler_class|
        handler = handler_class.new(self)
        if handler.responds?(str) && handler.respond_to?('query_result')
          return handler.query_result str, user_identity
        else
        end
      end
      return nil
    end

    def query(str, user_identity)
      responded = []
      post_handled = DismalTony::HandledResponse.new

      handlers.each do |handler_class|
        handler = handler_class.new(self)
        responded << handler if handler.responds? str
      end

      if responded.length == 1
        post_handled = DismalTony::HandledResponse.finish(responded.first.activate_handler( str, user_identity))
      elsif responded.empty?
        post_handled = DismalTony::HandledResponse.error
      else
        post_handled = DismalTony::HandledResponse.finish(responded.first.activate_handler( str, user_identity))
      end

      return post_handled
    end

    def quick_handle(qry = '', usr = DismalTony::UserIdentity.default_user, args = {})
      use_handler = @handlers.select { |handler|  handler.name.eql? qry}
      case use_handler.first.nil
      when false
        handle = use_handler.first.new(self)
        handle.data = args
        handle.activate_handler! qry, usr
      else
        DismalTony::HandledResponse.new("I'm sorry! I couldn't find that handler", nil)
      end
    end

    def say_through(interface, str)
      interface.send(Formatter::Printer.format(str, {}))
    end

    def say_opts(interface, str, opts)
      interface.send(Formatter::Printer.format(str, opts))
    end

    def say(str)
      @return_interface.send(Formatter::Printer.format(str))
    end
  end
end
