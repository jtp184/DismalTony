DismalTony.create_handler do 
  def handler_start
    @handler_name = 'push-git-project'
    @patterns = [/push (?:the )?(?<which>[\w_]+) project/i]
  end

  def activate_handler(query, user)
    "~e:smile I'll push the #{@data['which']} project."
  end

  def activate_handler!(query, user)
    parse query
    @vi.control(
      'git-project', 
      'push_project',
      {
        :nickname => @data['which'],
        :user => user
      }
      )
  end
end