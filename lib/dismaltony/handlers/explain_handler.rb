DismalTony.create_handler do
  def handler_start
    @handler_name = 'explain-handler'
    @patterns = ['^what (?:would|will) (?:you do|happen) if i (?:ask(?:ed)?|say) (?<second_query>.+)']
    @data = { 'second_query' => '' }
  end

  def activate_handler!(query, user)
    parse query
    message = vi.query(@data['second_query'], user).to_s
    DismalTony::HandledResponse.finish(message)
  end

  def activate_handler(query, user)
    parse query
    "I will explain what I'd do if you asked me \'#{@data['second_query']}\'"
  end
end
