DismalTony.create_handler(DismalTony::QueryMenu) do
    @handler_name = 'animal-moji-menu'
    @patterns = [/show me an animal emoji/i]

  def handler_start
    add_option(:dog, DismalTony::HandledResponse.finish('~e:dog Woof!'))
    add_option(:cat, DismalTony::HandledResponse.finish('~e:cat Meow!'))
    add_option(:fish, DismalTony::HandledResponse.finish('~e:fish Glub!'))
  end

  def menu(_query, _user)
    opts = @menu_choices.keys.map { |e| e.to_s.capitalize }
    DismalTony::HandledResponse.then_do(self, 'index', "~e:thumbsup Sure! You can choose from the following options: #{opts.join(', ')}")
  end
end
