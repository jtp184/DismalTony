DismalTony.create_handler do
  @handler_name = 'schedule-run'
  @patterns = [/run all schedule events/i]

  def activate_handler(_query, _uid)
    "~e:checkbox I'll run any outstanding schedule events"
  end

  def activate_handler!(_query, _uid)
    @vi.scheduler.execute
    DismalTony::HandledResponse.finish '~e:checkbox Okay! I ran the schedule events'
  end
end

DismalTony.create_handler do
  @handler_name = 'schedule-add-test'
  @patterns = [/add test schedule event/i]

  def activate_handler(_query, _uid)
    "I'll add a schedule event to test the scheduler"
  end

  def activate_handler!(_query, _uid)
    @vi.scheduler << DismalTony::ScheduleEvent.new(
      time: Time.now,
      query: 'Send a text to 8186208290 that says ~e:alarmclock Scheduler Test Message!'
    )
    DismalTony::HandledResponse.finish '~e:checkbox Okay! I added the schedule event'
  end
end
