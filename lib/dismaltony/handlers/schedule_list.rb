class ScheduleList < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'schedule-list'
    @patterns = ['^list\\s((people)|(who\\sis))\\son\\s(?<day>\\w+)\\s(?<event_key>\\w+\\??)', 'who\\sis\\sdoing\\s(?<day>\\w+)\\s(?<event_key>.+)\\?']
    @data = { 'day' => '', 'event_key' => '' }
  end

  def activate_handler!(query)
    parse query
    DismalTony::HandledResponse.new('', nil)
  end

  def activate_handler(query)
    parse query
    "I will return people doing #{@data['event_key']} on #{@data['day'].capitalize}."
  end
end
