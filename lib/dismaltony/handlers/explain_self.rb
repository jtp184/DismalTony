DismalTony.create_handler do
  def handler_start
    @handler_name = 'explain-self'
    @patterns = []
    @data = {}
  end

  def activate_handler(query, user); end

  def activate_handler!(query, user); end
end
