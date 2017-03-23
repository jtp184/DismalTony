DismalTony.create_handler do 
  def handler_start
    @handler_name = 'add-git-project'
    @patterns = [/add a new git project (?:called|named) (?<nickname>[\w_]+) (?:at )?(?<where>.+)/i]
  end

  def activate_handler(query, user)
    "~e:smile I'll add a new Git project."
  end

  def activate_handler!(query, user)
    parse query
    @vi.control(
      'git-project', 
      'add_project',
      {
        :nickname => @data['nickname'],
        :filepath => @data['where'],
        :user => user
      }
      )
  end
end