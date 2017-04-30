module DismalTony
  class QueryResolver
    attr_reader :handler_instances
    attr_reader :query

    def initialize(**opts)
      @handler_instances = (opts[:handler_instances] || [])
      @query = (opts[:query] || '')
    end

    def resolve(query, virtual)
      QueryResolver.new(
        :handler_instances => virtual.handlers.map { |e| e.new(virtual) }
        :query => query
        )
    end

    def query!(str = '', user_identity = DismalTony::UserIdentity::DEFAULT, silent = false)
      responded = []
      user_cs = user_identity.conversation_state
      post_handled = DismalTony::HandledResponse.new

      if ret = user_cs.return_to_handler
        handle = (handlers.select { |hand| hand.new(self).handler_name == ret.to_s }).first.new(self)
        handle.merge_data(user_cs.data_packet)
        post_handled = if user_cs.return_to_method == 'index'
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
      post_handled = if responded.empty?
        DismalTony::HandledResponse.error
      elsif responded.length == 1
        responded.first.activate_handler! str, user_identity
      elsif responded.any? { |hand| hand.handler_name == 'explain-handler' }
        (responded.select { |hand| hand.handler_name == 'explain-handler' }).first.activate_handler! str, user_identity
      else
        responded.first.activate_handler! str, user_identity
      end
    end
    post_handled
  end

  def match_query(str)
    responded = []
    handler_instances.each do |handler|
      responded << handler if handler.responds? str
    end
    responded
  end

  def match_name(str)
    responded = []
    handler_instances.each do |handler|
      responded << handler if handler.handler_name == str
    end
    responded
  end

  def resume_chain
    
  end

  alias call query!

  def query_result(str, user_identity = DismalTony::UserIdentity::DEFAULT)
    handlers.each do |handler_class|
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

    DismalTony::HandledResponse.error unless responded.length == 1
    DismalTony::HandledResponse.finish(responded.first.activate_handler(str, user_identity))
  end

  def quick_handle(qry = '', usr = DismalTony::UserIdentity::DEFAULT, args = {})
    use_handler = handlers.select { |handler| handler.new(self).handler_name == qry }
    return DismalTony::HandledResponse.new("I'm sorry! I couldn't find that handler", nil) if use_handler.nil? || use_handler == []
    handle = use_handler.first.new(self)
    handle.data = args
    handle.activate_handler! qry, usr
  end
end
end