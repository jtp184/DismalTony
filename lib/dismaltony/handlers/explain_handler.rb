class ExplainHandler < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'explain-handler'
    @patterns = ['^what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)'].map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    @data = { 'second_query' => '' }
  end

  def activate_handler!(query)
    parse query
    message = vi.query(@data['second_query']).to_s
    DismalTony::HandledResponse.new(message, nil)
  end

  def activate_handler(query)
    parse query
    "I will explain what I'd do if you asked me \'#{@data['second_query']}\'"
  end
end
