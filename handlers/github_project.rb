DismalTony.create_handler(DismalTony::QueryService) do
  @handler_name = 'git-project'
  @patterns = [/^git-project: (?<next>.+)/i]

  def handler_start
    @actions = %w[push_project push_deploy_project push_version_project version_push_deploy_project list_projects add_project]
  end

  def get_projects(usr)
    if !usr['githubprojects'].nil?
      usr['githubprojects']
    else
      {}
    end
  end

  def version_project(opts)
    old_dir = Dir.pwd
    Dir.chdir(get_projects(opts[:user])[opts[:nickname]])
    `nano lib/#{opts[:nickname]}/version.rb`
    Dir.chdir(old_dir)
  end

  def deploy_project(opts)
    old_dir = Dir.pwd
    Dir.chdir(get_projects(opts[:user])[opts[:nickname]])
    `cap production deploy`
    Dir.chdir(old_dir)
  end

  def push_project(opts)
    old_dir = Dir.pwd
    Dir.chdir(get_projects(opts[:user])[opts[:nickname]])
    `git add .`
    `git commit -m "Automated push at #{Time.now.to_s}"`
    `git push`
    Dir.chdir(old_dir)
    DismalTony::HandledResponse.finish "~e:smile Alright! We're all done."
  end

  def push_deploy_project(opts)
    push_project(opts)
    deploy_project(opts)
    DismalTony::HandledResponse.finish "~e:smile Alright! We're all done."
  end

  def push_version_project(opts)
    version_project(opts)
    push_project(opts)
  end

  def version_push_deploy_project(opts)
    version_project(opts)
    push_project(opts)
    deploy_project(opts)
    DismalTony::HandledResponse.finish "~e:smile Alright! We're all done."
  end

  def list_projects(opts)
    nicks = (get_projects opts[:user]).keys
    nicks.map(&:to_s)
    nicks.map { |e| "  #{e}" }
    DismalTony::HandledResponse.finish "~e:package The projects you have are: \n\n#{nicks.join('\n')}"
  end

  def add_project(opts)
    new_hash = get_projects(opts[:user]).merge(opts[:nickname] => opts[:filepath])
    opts[:user]['githubprojects'] = new_hash
    DismalTony::HandledResponse.finish "~e:checkbox Okay! I'll keep track of it."
  end
end
