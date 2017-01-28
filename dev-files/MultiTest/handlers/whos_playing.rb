class WhosPlaying < DismalTony::QueryHandler
  def handler_start
    @handler_name = 'whos-playing'
    @patterns = [/(?:who's|who is|whos) playing\??/]
    @data = {}
  end

  def activate_handler(query, user)
    "I'll tell you who's playing!"
  end

  def activate_handler!(query, user)
    everybody = $database.get_table(:users)
    resp_string = "Okay, here's who's playing: \n"
    everybody.each_with_index do |peep, index|
      resp_string += "#{index+1}. "
      resp_string += peep['first_name']
      resp_string += "\n"
    end
  end


end