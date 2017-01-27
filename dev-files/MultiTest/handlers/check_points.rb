class CheckPoints < DismalTony::QueryHandler
	 def handler_start
      @handler_name = 'check-points'
      @patterns = [/how many points does (?<person>\w+) have\??/]
    end

    def activate_handler!(query, user)
      parse query
      whom = ($database.get_table(:users).keep_if { |u| u['first_name'].eql? @data['person'] }).first
      DismalTony::HandledResponse.finish("~e:trophy #{@data['person']} has #{whom['points']} points")
    end

    def activate_handler(query, user)
      parse query
      "I'll tell you how many points #{@data['person']} has!"
    end
end