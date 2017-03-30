DismalTony.create_handler do
  def handler_start
    @handler_name = 'add-points'
    # @patterns = ["(?:(?:give)|(?:add)) (?<who>\w+)? ?(?<points>\d+) points(?: to (?<who>\w+))?"]
    @patterns = [/((give)|(add)) (?<who>\w+)? ?(?<points>\d+) points( to (?<who>\w+))?/i]
    @data = {}
  end

  def activate_handler!(query, user)
    parse query
    whom = ($database.get_table(:users).keep_if { |u| u['first_name'].eql? @data['who'] }).first
    whom = user if @data['who'].eql? 'me'
    if whom['points'].nil?
      whom['points'] = @data['points'].to_i
    else
      pts = whom['points'].to_i
      pts += @data['points'].to_i
      whom['points'] = pts
    end
    DismalTony::HandledResponse.finish("~e:star Cool! You gave #{user['first_name']} #{@data['points']} points!")
  end

  def activate_handler(query, _user)
    parse query
    "I'll give #{@data['who']} #{@data['points']} points"
  end
end
