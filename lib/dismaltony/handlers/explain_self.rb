class ExplainSelf < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'explain-self'
    @patterns = []
    @data = {}
  end

  def activate_handler(query, user); end

  def activate_handler!(query, user); end
end
