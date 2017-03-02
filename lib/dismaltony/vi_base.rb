module DismalTony
  class VIBase
    attr_accessor :name
    attr_accessor :return_interface
    attr_accessor :emotes
    attr_accessor :handlers
    attr_accessor :handler_directory

    def initialize(**opts)
      @name = (opts[:name] || "Tony".freeze)
      @return_interface = (opts[:the_interface].new(self) || DismalTony::ConsoleInterface.new(self))
      @handler_directory = (opts[:handler_directory] || '/')
      @handlers = []
    end

    def identify_user; end

    def list_handlers
      @handlers.map { |e| e.new(self).handler_name.to_s }
    end

    def load_handlers_from(directory)
      found_files = (Dir.entries directory).reject { |e| !(e =~ /.+\.rb/) }
      found_files.each do |file|
        load "#{directory}/#{File.basename(file)}"
      end
      DismalTony::QueryHandler.list.each do |handler|
        @handlers << handler
      end
    end

    def load_handlers
      load_handlers_from @handler_directory
    end

    def load_handlers!(str)
      @handler_directory = str
      load_handlers
    end

    def query!(str = '', user_identity = DismalTony::UserIdentity.default_user)
      responded = []
      post_handled = DismalTony::HandledResponse.new

      if user_identity.conversation_state.return_to_handler
        handle = (@handlers.select { |h| h.new.handler_name == "#{user_identity.conversation_state.return_to_handler}"}).first.new(self)
        handle.data = user_identity.conversation_state.data_packet
        if user_identity.conversation_state.return_to_method == 'index'
          post_handled = handle.activate_handler! str, user_identity
        elsif user_identity.conversation_state.return_to_args
          post_handled = handle.method(user_identity.conversation_state.return_to_method.to_sym).call(user_identity.conversation_state.return_to_args.split(", ") + [str, user_identity])
        else
          post_handled = handle.method(user_identity.conversation_state.return_to_method.to_sym).call(str, user_identity)
        end
      elsif user_identity.conversation_state.use_next

      else
        @handlers.each do |handler_class|
          handler = handler_class.new(self)
          if handler.responds? str
            responded << handler
          # puts 'handled by #{handler.handler_name}'
        end
      end

      if responded.empty?
        post_handled = DismalTony::HandledResponse.finish "~e:frown I'm sorry, I didn't understand that!"
      elsif responded.length == 1
        post_handled = responded.first.activate_handler! str, user_identity
      elsif (responded.count { |e| e.handler_name.eql? 'explain-handler' }) > 0
        post_handled = ExplainHandler.new(self).activate_handler! str, user_identity
      else
          # puts print responded
          post_handled = responded.first.activate_handler! str, user_identity
        end
      end
      say_opts @return_interface, post_handled.to_s, post_handled.format
      post_handled.conversation_state.from_h! ({:user_identity => user_identity, :last_recieved_time => Time.now})
      user_identity.modify_state(post_handled.conversation_state)
      post_handled
    end

    def info_query(str)
      handlers.each do |handler_class|
        handler = handler_class.new
        if handler.responds?(str) && handler.responds_to?('info_handler')
          return handler.info_handler str
        end
      end
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
        post_handled = DismalTony::HandledResponse.finish("~e:frown I'm sorry, I didn't understand that!")
      else
        post_handled = DismalTony::HandledResponse.finish(responded.first.activate_handler( str, user_identity))
      end
      
      return post_handled
    end

    def quick_handle(qry = '', args = {})
      use_handler = @handlers.select { |handler|  handler.name.eql? qry}

      case use_handler.nil?
      when false
        handle = use_handler.new(self)
        handle.data = args
      else
        DismalTony::HandledResponse.new("I'm sorry! I couldn't find that handler", nil)
      end
    end

    def say_through(interface, str)
      interface.send(Formatter::Printer.format(str))
    end

    def say_opts(interface, str, opts)
      interface.send(Formatter::Printer.format(str, opts))
    end

    def say(str)
      @return_interface.send(Formatter::Printer.format(str))
    end

    alias_method :say_back, :say
  end
end
