DismalTony.create_handler do
  def handler_start
    @handler_name = 'self-diagnostic'
    @patterns = ["(?:#{@vi.name}, )?(?:run a )self diagnostic"]
  end

  def activate_handler(_q, _u)
    "I'll run a diagnostic on myself!"
  end

  def activate_handler!(query, user)
    begin
      return_string = "~e:checkbox Diagnostic Successful!\n\n"
      return_string << "    Time: #{Time.now.strftime('%F %l:%M%P')}\n"
      return_string << "    VI: #{@vi.name}\n"
      return_string << "    Version: #{DismalTony::VERSION}\n"
      return_string << "    User: #{user['nickname']}\n"
      return_string << "    Handlers: #{@vi.handlers.length}\n"
      return_string << "    Fremont, CA: #{@vi.query_result('What is the temperature in Fremont')['temp']}˚F\n"
    rescue StandardError => err
      return_string = "~e:cancel Something went wrong!\n#{puts err}"
    end
    DismalTony::HandledResponse.finish return_string      
  end
end