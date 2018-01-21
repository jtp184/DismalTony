DismalTony.create_handler(DismalTony::CannedResponse) do
  @handler_name = 'greeter'
  @patterns = [/^hello$/i]

  def handler_start
    @responses = ['~e:wave Hello!', '~e:smile Greetings!', '~e:rocket Hi!', '~e:star Hello!', '~e:snake Greetings!', '~e:cat Hi!', '~e:octo Greetings!', '~e:spaceinvader Hello!']
  end
end
