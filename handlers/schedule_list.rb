DismalTony.create_handler do
  def handler_start
    @handler_name = 'schedule-list'
    @patterns = [/list\s(?:people)? ?(?:who)? ?(?:is|are) on (?<day>\w+) (?<event_key>\w+)/, /who\\sis\\sdoing\\s(?<day>\\w+)\\s(?<event_key>.+)\\?/]
    @data = { 'day' => '', 'event_key' => '' }
  end

  def activate_handler!(query, _user)
    parse query
    people = get_everyone(@data['day'], @data['event_key'])
    response_string = "~e:calendar Okay! Here's who's doing that:\n"
    people.each do |person|
      response_string << "\t#{person}\n"
    end
    DismalTony::HandledResponse.finish response_string
  end

  def query_result(query, _user)
    parse query
    get_everyone(@data['day'], @data['event_key'])
  end

  def get_everyone(_day, _event)
    # Would in theory get the people from the database.
    []
  end

  def activate_handler(query, _user)
    parse query
    "I will return people doing #{@data['event_key']} on #{@data['day'].capitalize}."
  end
end
