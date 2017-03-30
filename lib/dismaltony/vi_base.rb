module DismalTony
  class VIBase
    attr_accessor :name
    attr_accessor :return_interface
    attr_accessor :handlers
    attr_accessor :data_store

    def initialize(**opts)
      @name = (opts[:name] || 'Tony'.freeze)
      @return_interface = if opts[:return_interface]
                            opts[:return_interface]
                          else
                            DismalTony::ConsoleInterface.new(self)
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
        handle = (@handlers.select { |h| h.new(self).handler_name == user_identity.conversation_state.return_to_handler.to_s }).first.new(self)
        handle.data = user_identity.conversation_state.data_packet
        post_handled = if user_identity.conversation_state.return_to_method == 'index'
                         handle.activate_handler! str, user_identity
                       else
                         post_handled = if handle.respond_to? user_identity.conversation_state.return_to_method
                                          if user_identity.conversation_state.return_to_args
                                            handle.method(user_identity.conversation_state.return_to_method.to_sym).call(user_identity.conversation_state.return_to_args.split(', ') + [str, user_identity])
                                          else
                                            handle.method(user_identity.conversation_state.return_to_method.to_sym).call(str, user_identity)
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
                       elsif responded.any? { |h| h.handler_name = 'explain-handler' }
                         (responded.select { |h| h.handler_name = 'explain-handler' }).first.activate_handler! str, user_identity
                       else
                         responded.first.activate_handler! str, user_identity
                       end
                       end
      say_opts(@return_interface, post_handled.to_s, post_handled.format) unless post_handled.format[:quiet]
      post_handled.conversation_state.from_h!(user_identity: user_identity, last_recieved_time: Time.now)
      user_identity.conversation_state = post_handled.conversation_state
      @data_store.on_query(post_handled)
      post_handled
    end

    def query_result!(str, user_identity = DismalTony::UserIdentity.default_user)
      @handlers.each do |handler_class|
        handler = handler_class.new(self)
        if handler.responds?(str) && handler.respond_to?('query_result')
          return handler.query_result str, user_identity
        end
      end
      nil
    end

    def query(str, user_identity)
      responded = []

      handlers.each do |handler_class|
        handler = handler_class.new(self)
        responded << handler if handler.responds? str
      end

      post_handled = if responded.length == 1
                       DismalTony::HandledResponse.finish(responded.first.activate_handler(str, user_identity))
                     elsif responded.empty?
                       DismalTony::HandledResponse.error
                     else
                       DismalTony::HandledResponse.finish(responded.first.activate_handler(str, user_identity))
                     end

      post_handled
    end

    def quick_handle(qry = '', usr = DismalTony::UserIdentity.default_user, args = {})
      use_handler = @handlers.select { |handler| handler.new(self).handler_name == qry }
      case use_handler.first.nil?
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

    def control(subject, verb, params = {})
      the_remote = (@handlers.select { |r| r.new(self).handler_name == subject }).first.new(self)
      if the_remote.actions.include? verb
        the_method = the_remote.method(verb.to_sym)
        if params == {}
          the_method.call
        else
          the_method.call(params)
        end
      else
        DismalTony::HandledResponse.finish("Sorry, that didn't work!")
      end
    end
  end
end
