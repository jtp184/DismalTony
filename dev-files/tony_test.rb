Dir.chdir('..')

require 'bundler'
Bundler.require(:development, :default)

#   tt    [[[[ ]]]]
#   tt    [[     ]] nn nnn  yy   yy
#   tttt  [[     ]] nnn  nn yy   yy
#   tt    [[     ]] nn   nn  yyyyyy
#    tttt [[[[ ]]]] nn   nn      yy
#                            yyyyy
@laptop_emoji = DismalTony::EmojiDictionary['laptop']

# @db = DismalTony::LocalStore.create('./store.yml')
# @db.users << DismalTony::UserIdentity.new(
# 	:user_data => {"nickname" => 'Justin'}
# 	)
# puts "[#{DismalTony::EmojiDictionary['exclamationmark']}]: WARNING not idle (#{@db.users.first.conversation_state.return_to_handler} => #{@db.users.first.conversation_state.return_to_method} #{@db.users.first.conversation_state.data_packet})" unless @db.users.first.conversation_state.is_idle
@db = DismalTony::LocalStore.new(
  filepath: './store.yml'
)
@db.load
DismalTony::HandlerRegistry.load_handlers! 'handlers'
@tony = DismalTony::VIBase.new(data_store: @db)

def qp(str, debug = false)
  puts "[#{@laptop_emoji}]: #{str}"
  puts " #{@db.users.first.conversation_state.inspect}" if debug
  if debug
    puts
    puts (@tony.query! str, @db.users.first).inspect
  else
    @tony.query!(str, @db.users.first)
  end
  puts " #{@db.users.first.conversation_state.inspect}" if debug
  puts
end

# qp 'add test schedule event'
# sleep 2
qp 'run all schedule events'
# qp 'Send a text to 8186208290 that says Hello'