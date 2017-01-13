class ExplainSelf < Tony::QueryHandler
  def initialize
    @handler_name = 'explain-self'
    @patterns = [].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    @data = {}
  end

  def activate_handler(query, vi); end

  def activate_handler!(query, vi); end
end
