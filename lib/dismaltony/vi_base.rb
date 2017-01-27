module DismalTony
  class VIBase
    attr_accessor :name
    attr_accessor :return_interface
    attr_accessor :emotes
    attr_accessor :handlers
    attr_accessor :handler_directory

    def initialize(the_name = 'Tony', the_interface = DismalTony::ConsoleInterface.new)
      @name = the_name
      @return_interface = the_interface
      @emotes = DismalTony::EmojiDictionary.new.to_h
      @handler_directory = '/'
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

    def query!(str = '', the_user = DismalTony::UserIdentity.default_user)
      responded = []
      post_handled = DismalTony::HandledResponse.new

      if the_user.conversation_state.return_to_handler
        handle = (@handlers.select { |h| h.new.handler_name == "#{the_user.conversation_state.return_to_handler}"}).first.new(self)
        handle.data = the_user.conversation_state.data_packet
        post_handled = handle.method(the_user.conversation_state.return_to_method.to_sym).call(str, the_user)
      elsif the_user.conversation_state.use_next

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
        post_handled = responded.first.activate_handler! str, the_user
      elsif (responded.count { |e| e.handler_name.eql? 'explain-handler' }) > 0
        post_handled = ExplainHandler.new(self).activate_handler! str, the_user
      else
          # puts print responded
          post_handled = responded.first.activate_handler! str, the_user
        end
      end
      say post_handled.to_s
      post_handled.conversation_state.from_h! ({:the_user => the_user, :last_recieved_time => Time.now})
      the_user.modify_state(post_handled.conversation_state)
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
    
    def query(str, the_user)
      responded = []
      post_handled = DismalTony::HandledResponse.new

      handlers.each do |handler_class|
        handler = handler_class.new(self)
        responded << handler if handler.responds? str
      end

      if responded.length == 1
        post_handled = DismalTony::HandledResponse.finish(responded.first.activate_handler( str, the_user))
      elsif responded.empty?
        post_handled = DismalTony::HandledResponse.finish("~e:frown I'm sorry, I didn't understand that!")
      else
        post_handled = DismalTony::HandledResponse.finish(responded.first.activate_handler( str, the_user))
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
      pat = /(?:~e:(?<emote>\w+\b) )?(?<message>.+)/
      md = pat.match str
      return interface.send(response(md['message'], md['emote'])) unless md.named_captures['emote'].nil?
      interface.send(response(md['message'], 'smile'))
    end

    def say(str)
      pat = /(?:~e:(?<emote>\w+\b) )?(?<message>.+)/
      md = pat.match str
      if str =~ pat
        if md['emote'].nil?
          @return_interface.send(response(md['message'], 'smile'))
        else
          @return_interface.send(response(md['message'], md['emote']))
        end
      end
    end

    def response(str, emo)
      "[#{@emotes[emo]}]" + ": #{str}"
    end
  end
end
