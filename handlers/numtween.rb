DismalTony.create_handler(DismalTony::QueryResult) do
  @handler_name = 'numtween'
  @patterns = [/print numbers between (?<start>\d+) and (?<end>\d+)/i]

  def apply_format(input)
    result_string = '~e:smile Okay! Here they are: '
    result_string << input.join(', ')
  end

  def query_result(query, _uid)
    parse query
    (@data['start'].to_i..@data['end'].to_i).to_a
  end
end
