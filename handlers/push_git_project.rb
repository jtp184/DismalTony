DismalTony.create_handler do
  @handler_name = 'push-git-project'
  @patterns = [/push (?:the )?(?<which>[\w_]+) project/i]

  def activate_handler(_query, _user)
    "~e:smile I'll push the #{@data['which']} project."
  end

  def activate_handler!(query, user)
    parse query
    @vi.use_service(
      'git-project',
      'push_project',
      nickname: @data['which'],
      user: user
    )
  end
end
