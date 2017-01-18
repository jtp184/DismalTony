class ExplainSelf < Tony::QueryHandler
  def handler_start
    @handler_name = 'explain-self'
    @patterns = [].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    @data = {}
  end

  def activate_handler(query); end

  def activate_handler!(query); end
end
